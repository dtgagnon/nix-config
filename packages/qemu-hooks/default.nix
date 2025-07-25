{ lib
, pkgs
, stdenv
, vmDomainName ? "win11-GPU" #TODO: update this to accept a list of the vmDomains I want this to work for
, gpuBusId ? "" #config.${namespace}.hardware.gpu.dGPU.busId
, dgpuDeviceIds ? [ ":" ":" ] #config.${namespace}.hardware.gpu.dGPU.deviceIds
, ...
}:
let
  inherit (lib) replaceStrings getExe';
  inherit (lib.lists) head last;

  gpuAudioBusId = replaceStrings [ ".0" ] [ ".1" ] gpuBusId;
  parsedDeviceIds = map
    (id: {
      vendor = builtins.elemAt (builtins.split ":" id) 0;
      product = builtins.elemAt (builtins.split ":" id) 2;
    })
    dgpuDeviceIds;
  gpuIds = head parsedDeviceIds;
  gpuAudioIds = last parsedDeviceIds;
in
stdenv.mkDerivation {
  pname = "qemu-hooks";
  version = "0.2";

  buildInputs = with pkgs; [
    kmod
    coreutils
    systemd
    libvirt
    psmisc
    usbutils
    xmlstarlet
  ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    # --- give-vfio-dgpu Script --- #
    cat > $out/bin/give-vfio-dgpu << 'EOF'
    #!${pkgs.stdenv.shell}
    set -e

    # Helper function to check if a device is using a specific driver
    is_using_driver() {
      local device_id=$1
      local driver=$2

      if [ -e "/sys/bus/pci/devices/$device_id/driver" ]; then
        current_driver=$(basename $(readlink "/sys/bus/pci/devices/$device_id/driver" 2>/dev/null))
        [ "$current_driver" = "$driver" ]
      else
        return 1
      fi
    }

    # Helper function to unbind a device from its current driver
    unbind_from_current_driver() {
      local device_id=$1
      local device_name=$2

      if [ -e "/sys/bus/pci/devices/$device_id/driver" ]; then
        local current_driver=$(basename $(readlink "/sys/bus/pci/devices/$device_id/driver" 2>/dev/null))
        echo "[HOOK] Unbinding $device_name from $current_driver..."
        echo "$device_id" > /sys/bus/pci/drivers/$current_driver/unbind || {
          echo "[ERROR] Failed to unbind $device_name from $current_driver"
          return 1
        }
        return 0
      else
        echo "[HOOK] $device_name has no driver bound, nothing to unbind"
        return 0
      fi
    }

    # Helper function to bind device to vfio-pci
    bind_to_vfio() {
      local device_id=$1
      local device_name=$2
      local vendor_id=$3
      local product_id=$4

      echo "[HOOK] Binding $device_name to vfio-pci..."

      # Try new_id method first
      if [ -n "$vendor_id" ] && [ -n "$product_id" ]; then
        echo "[HOOK] Using new_id method for $device_name ($vendor_id:$product_id)"
        echo "$vendor_id $product_id" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
      fi

      # Check if bind succeeded with new_id
      if ! is_using_driver "$device_id" "vfio-pci"; then
        # Try direct binding if new_id didn't work
        echo "[HOOK] Using direct binding for $device_name"
        echo "$device_id" > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || {
          echo "[ERROR] Failed to bind $device_name to vfio-pci"
          return 1
        }
      fi

      # Final verification
      if is_using_driver "$device_id" "vfio-pci"; then
        echo "[HOOK] Successfully bound $device_name to vfio-pci"
        return 0
      else
        echo "[ERROR] Failed to bind $device_name to vfio-pci"
        return 1
      fi
    }

    echo "[HOOK] Starting GPU passthrough to VFIO..."

    # Stop services
    echo "[HOOK] Stopping services..."
    echo "1" > /var/lib/systemd/qemu-hooks-state

    # Kill dGPU processes
    DGPU_DEVICES="/dev/nvidia*"
    if ${getExe' pkgs.psmisc "fuser"} ''$DGPU_DEVICES 2>&1; then
      echo "[HOOK] Killing processes:"
      ${getExe' pkgs.psmisc "fuser"} -vk ''$DGPU_DEVICES
    else
      echo "[HOOK] No processes found using dGPU"
    fi
    sleep 2

    # Unbind devices from host driver FIRST
    echo "[HOOK] Unbinding devices from host drivers..."
    unbind_from_current_driver "${gpuBusId}" "GPU" || exit 1
    if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}" ]; then
      unbind_from_current_driver "${gpuAudioBusId}" "Audio Device" || echo "[WARNING] Failed to unbind audio device."
    fi

    # NOW, unload the modules (with new strict error handling)
    echo "[HOOK] Unloading NVIDIA modules..."
    for module in nvidia_uvm nvidia_drm nvidia_modeset nvidia i2c_nvidia_gpu; do
      if lsmod | grep -q "^$module "; then
        echo "[HOOK] Unloading $module module..."
        modprobe -r "$module" || {
          echo "[ERROR] Failed to unload '$module'. Module may have reloaded or is in use."
          echo "[ERROR] Aborting script."
          exit 1
        }
      fi
    done

    echo "[HOOK] Verifying all NVIDIA modules are unloaded..."
    if lsmod | grep -q "nvidia"; then
      echo "[ERROR] One or more NVIDIA modules are still loaded. Aborting."
      lsmod | grep "nvidia" # Show the problematic modules
      exit 1
    else
      echo "[HOOK] All NVIDIA modules successfully unloaded."
    fi

    # Load VFIO modules
    echo "[HOOK] Ensuring VFIO modules are loaded..."
    for module in vfio vfio-pci vfio_iommu_type1; do
      modprobe $module || echo "[ERROR] Failed to load $module module"
    done

    # Bind GPU devices to vfio-pci
    echo "[HOOK] Binding devices to vfio-pci driver..."
    bind_to_vfio "${gpuBusId}" "GPU" "${gpuIds.vendor}" "${gpuIds.product}" || exit 1

    if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}" ]; then
      bind_to_vfio "${gpuAudioBusId}" "Audio Device" "${gpuAudioIds.vendor}" "${gpuAudioIds.product}" || echo "[WARNING] Failed to bind audio device."
    fi

    # Final verification
    echo "[HOOK] Verifying device bindings..."
    if is_using_driver "${gpuBusId}" "vfio-pci"; then
      echo "[HOOK] GPU successfully bound to vfio-pci"
      echo "[SUCCESS] GPU successfully prepared for passthrough"
      exit 0
    else
      echo "[ERROR] Failed to prepare GPU for passthrough"
      exit 1
    fi
    EOF


    # --- give-host-dGPU Script --- #
    cat > $out/bin/give-host-dgpu << 'EOF'
    #!${pkgs.stdenv.shell}
    set -e

    echo "[INFO] Starting GPU return to host..."

    # Helper function for unbinding devices from vfio-pci
    unbind_from_vfio() {
      local device_id=$1
      local device_name=$2

      if [ -e /sys/bus/pci/devices/''${device_id}/driver ] && \
      [ "$(basename "$(readlink /sys/bus/pci/devices/''${device_id}/driver)")" = "vfio-pci" ]; then
        echo "[INFO] Unbinding $device_name from vfio-pci..."
        echo "''${device_id}" > /sys/bus/pci/drivers/vfio-pci/unbind || echo "[WARN] Failed to unbind $device_name"
      else
        echo "[INFO] $device_name not bound to vfio-pci, nothing to unbind"
      fi
    }

    # Helper function to bind a device to its driver
    bind_device() {
      local device_id=$1
      local driver=$2
      local device_name=$3
      local vendor_id=$4
      local product_id=$5

      echo "[DEBUG] Checking current driver for $device_name..."
      if [ -e "/sys/bus/pci/devices/''${device_id}/driver" ] && \
         [ "$(basename "$(readlink /sys/bus/pci/devices/''${device_id}/driver)")" = "$driver" ]; then
         echo "[INFO] $device_name is already bound to $driver. Nothing to do."
         return 0
      fi

      echo "[INFO] Attempting to bind $device_name to $driver..."

      # Try direct bind first as it's most reliable when driver is loaded
      if [ -e "/sys/bus/pci/devices/''${device_id}" ] && [ -d "/sys/bus/pci/drivers/$driver" ]; then
        echo "[DEBUG] Trying direct bind for $device_name at ''${device_id}"
        echo "''${device_id}" > "/sys/bus/pci/drivers/$driver/bind" 2>/dev/null

        # Check if bind was successful
        if [ -e /sys/bus/pci/devices/''${device_id}/driver ] && \
        [ "$(basename "$(readlink /sys/bus/pci/devices/''${device_id}/driver)")" = "$driver" ]; then
          echo "[INFO] Successfully bound $device_name to $driver"
          return 0
        fi
      fi

      # If vendor/product IDs provided, try new_id method
      if [ -n "$vendor_id" ] && [ -n "$product_id" ] && [ -f "/sys/bus/pci/drivers/$driver/new_id" ]; then
        echo "[DEBUG] Using new_id method for $device_name ($vendor_id:$product_id)"
        echo "$vendor_id $product_id" > /sys/bus/pci/drivers/$driver/new_id 2>/dev/null
        sleep 1

        # Check if bind was successful
        if [ -e /sys/bus/pci/devices/''${device_id}/driver ] && \
          [ "$(basename "$(readlink /sys/bus/pci/devices/''${device_id}/driver)")" = "$driver" ]; then
          echo "[INFO] Successfully bound $device_name to $driver using new_id"
          return 0
        fi
      fi

      echo "[WARN] Failed to bind $device_name to $driver"
      return 1
    }

    # Unbind devices from vfio-pci
    echo "[INFO] Unbinding GPU device from vfio-pci..."
    unbind_from_vfio "${gpuBusId}" "GPU"
    echo "[INFO] Unbinding GPU audio device from vfio-pci..."
    unbind_from_vfio "${gpuAudioBusId}" "audio device"
    sleep 1

    # Load NVIDIA kernel modules in correct order
    echo "[INFO] Loading NVIDIA kernel modules..."

    # Load modules with proper error handling, handle nvidia_drm separately
    for module in i2c_nvidia_gpu nvidia nvidia_modeset nvidia_uvm; do
      if ! lsmod | grep -q "^$module "; then
        modprobe $module 2>/dev/null || echo "[WARN] Module $module failed to load"
      fi
    done

    # Load nvidia_drm with fbdev=0 and modeset=0 to prevent console binding and display initialization
    if ! lsmod | grep -q "^nvidia_drm "; then
      echo "[INFO] Loading nvidia_drm with fbdev=0 and modeset=0..."
      modprobe nvidia_drm fbdev=0 modeset=0 2>/dev/null || echo "[WARN] Module nvidia_drm failed to load with required parameters"
    fi

    # Check if nvidia module loaded successfully
    if ! lsmod | grep -q "^nvidia "; then
      echo "[ERROR] Failed to load NVIDIA driver. Is the module built for this kernel?"
      exit 1
    fi

    echo "[INFO] NVIDIA driver loaded successfully"

    # Bind GPU devices to their drivers
    echo "[INFO] Binding devices to host drivers..."

    # Bind GPU to nvidia driver
    bind_device "${gpuBusId}" "nvidia" "GPU" "${gpuIds.vendor}" "${gpuIds.product}"

    # Bind GPU audio device to snd_hda_intel
    modprobe snd_hda_intel 2>/dev/null || echo "[WARN] Failed to load snd_hda_intel"
    if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}" ]; then
      bind_device "${gpuAudioBusId}" "snd_hda_intel" "audio device" "${gpuAudioIds.vendor}" "${gpuAudioIds.product}"
    fi

    # Final status check
    echo "[INFO] Device binding status:"
    GPU_DRIVER=$(basename $(readlink -f /sys/bus/pci/devices/${gpuBusId}/driver 2>/dev/null || echo "none"))
    AUDIO_DRIVER=$(basename $(readlink -f /sys/bus/pci/devices/${gpuAudioBusId}/driver 2>/dev/null || echo "none"))

    echo "[INFO] GPU driver: $GPU_DRIVER"
    echo "[INFO] Audio driver: $AUDIO_DRIVER"

    if [ "$GPU_DRIVER" = "nvidia" ]; then
      echo "[SUCCESS] GPU successfully returned to host"
      echo "0" > /var/lib/systemd/qemu-hooks-state
    else
      echo "[WARNING] GPU may not be properly bound to nvidia driver"
    fi

    if [ "$AUDIO_DRIVER" = "snd_hda_intel" ]; then
      echo "[SUCCESS] Audio device successfully bound to snd_hda_intel"
    else
      echo "[WARNING] Audio device binding failed, manual intervention may be required"
    fi
    EOF


    # --- virsh-check-usb Script --- #
    cat > $out/bin/virsh-check-usb << 'EOF'
    #!${pkgs.stdenv.shell}
    set -e

    # Use a temporary file for the XML definition and ensure it gets cleaned up on script exit
    VM_XML=$(mktemp)
    trap "rm -f $VM_XML" EXIT

    # Get the list of USB devices currently defined in the VM's configuration
    ATTACHED_USBS=( $(virsh dumpxml ${vmDomainName} | \
    ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -m "/domain/devices/hostdev[@type='usb']" \
    -v "source/vendor/@id" -o ":" -v "source/product/@id" -nl | \
    sed -e 's/0x\([0-9a-f]*\)/\1/g') )

    # If no USBs are attached in the first place, there's nothing to do
    if [ ''${#ATTACHED_USBS[@]} -eq 0 ]; then
      echo "No USB devices to check for ${vmDomainName}."
      exit 0
    fi

    # Dump the current XML configuration to our temporary file so we can edit it
    virsh dumpxml ${vmDomainName} > "$VM_XML"
    MODIFIED=false

    for usb in "''${ATTACHED_USBS[@]}"; do
      # For each device in the config, check if it's actually connected to the host system
      if ! ${pkgs.usbutils}/bin/lsusb | grep -q "$usb"; then
        echo "USB device $usb is defined in VM but not connected to host. Removing..."
        vendor=$(echo "$usb" | cut -d':' -f1)
        product=$(echo "$usb" | cut -d':' -f2)

        # If not connected, edit the XML file in-place (-L) to remove the device node
        ${pkgs.xmlstarlet}/bin/xmlstarlet ed -L -d "/domain/devices/hostdev[source/vendor/@id='0x$vendor'][source/product/@id='0x$product']" "$VM_XML"
        MODIFIED=true
      fi
    done

    # If we removed any devices, MODIFIED will be true
    # We then redefine the VM using the cleaned-up configuration file
    if [ "$MODIFIED" = true ]; then
      echo "Applying updated USB configuration to ${vmDomainName}..."
      virsh define "$VM_XML"
    fi
    EOF


    # --- virsh-detach-usb Script --- #
    cat > $out/bin/virsh-detach-usb << 'EOF'
    #!${pkgs.stdenv.shell}
    set -e

    # Get the vendor:product IDs of USB devices defined in the VM
    ATTACHED_IDS=( $(virsh dumpxml ${vmDomainName} | \
    ${pkgs.xmlstarlet}/bin/xmlstarlet sel -t -m "/domain/devices/hostdev[@type='usb']" -v "source/vendor/@id" -o ":" -v "source/product/@id" -nl | \
    sed 's/0x//g') )

    if [ ''${#ATTACHED_IDS[@]} -eq 0 ]; then
      echo "No USB devices are attached to ${vmDomainName}."
      exit 0
    fi

    echo "Select a USB device to detach:"
    i=1
    # Use an associative array to safely map the menu number to the device ID
    declare -A MENU_MAP
    for id in "''${ATTACHED_IDS[@]}"; do
      # Find the corresponding line in lsusb, handling cases where it's not connected
      line=$(${pkgs.usbutils}/bin/lsusb | grep "$id" || true)
      if [ -n "$line" ]; then
        name=$(echo "$line" | sed "s/.*$id[[:space:]]//") # Extract name after the ID
        echo "$i) $name ($id)"
      else
        echo "$i) [Disconnected Device] ($id)"
      fi
      MENU_MAP[$i]=$id
      ((i++))
    done

    read -p "Enter number: " chosen_idx

    # Get the chosen ID from our map and validate it
    chosen_id_full=''${MENU_MAP[$chosen_idx]}
    if [ -z "$chosen_id_full" ]; then
      echo "Invalid selection."
      exit 1
    fi

    chosen_vendor=$(echo "$chosen_id_full" | cut -d':' -f1)
    chosen_product=$(echo "$chosen_id_full" | cut -d':' -f2)

    echo "Detaching device $chosen_id_full from ${vmDomainName}..."

    # Use --persistent to hot-unplug AND update the persistent configuration
    virsh detach-device ${vmDomainName} --persistent /dev/stdin << 'EOF_'
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source>
        <vendor id='0x$chosen_vendor'/>
        <product id='0x$chosen_product'/>
      </source>
    </hostdev>
    EOF_
    echo "Device detached successfully."
    EOF


    # --- virsh-attach-usb Script --- #
    cat > $out/bin/virsh-attach-usb << 'EOF'
    #!${pkgs.stdenv.shell}
    set -e

    IFS=$'\n'
    # Get lists of USB device names and their vendor:product IDs
    USB_DEVICES=( $(${pkgs.usbutils}/bin/lsusb | sed 's/^Bus[[:space:]][0-9]*[[:space:]]Device[[:space:]][0-9]*:[[:space:]]ID[[:space:]]//') )
    USB_IDS=( $(${pkgs.usbutils}/bin/lsusb | grep -oE '[0-9a-f]{4}:[0-9a-f]{4}') )

    # Display a menu for the user to choose from
    echo "Select a USB device to attach:"
    i=1
    for device in "''${USB_DEVICES[@]}"; do
      echo "$i) $device (''${USB_IDS[(($i-1))]})"
      ((i++))
    done

    read -p "Enter number: " chosenidx
    ((chosenidx--))

    # Get the vendor and product ID for the chosen device
    chosen_vendor=$(echo "''${USB_IDS[$chosenidx]}" | cut -d':' -f1)
    chosen_id=$(echo "''${USB_IDS[$chosenidx]}" | cut -d':' -f2)

    echo "Attaching ''${USB_DEVICES[$chosenidx]} to ${vmDomainName}..."

    # This single command hot-plugs the device (if VM is running) AND
    # saves the change to the VM's configuration for future boots.
    # It reads the device XML from standard input via the heredoc.
    virsh attach-device ${vmDomainName} --persistent /dev/stdin << 'EOF_'
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source>
        <vendor id='0x$chosen_vendor'/>
        <product id='0x$chosen_id'/>
      </source>
    </hostdev>
    EOF_
    echo "Device attached successfully."
    EOF


    # --- qemu-hook-dispatcher --- #
    cat > $out/bin/qemu-hook-dispatcher << 'EOF'
    #!${pkgs.stdenv.shell}
    set -e

    VM_NAME="$1"
    COMMAND="$2"

    # For a specific VM, run scripts on start/stop
    if [ "$VM_NAME" == "${vmDomainName}" ]; then
      if [ "$COMMAND" == "prepare" ]; then
        ${pkgs.coreutils-full}/bin/echo "preparing"
        virsh-check-usb
        give-vfio-dgpu
      elif [ "$COMMAND" == "started" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-3,16-23
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-3,16-23
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-3,16-23
      elif [ "$COMMAND" == "release" ]; then
        give-host-dgpu
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-23
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-23
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-23
      fi
    fi
    EOF


    # --- Scripts Block End --- #

    # Make all the scripts executable
    chmod +x $out/bin/*
  '';
}
