{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf getExe' removePrefix substring stringLength replaceStrings;
  cfg = config.${namespace}.virtualisation.kvm;

  gpuBusId = config.${namespace}.hardware.gpu.dGPU.busId;
  gpuAudioBusId = replaceStrings [".0"] [".1"] gpuBusId;
  gpuMfg = config.${namespace}.hardware.gpu.dGPU.mfg;
  gpuDeviceIds = config.${namespace}.hardware.gpu.dGPU.deviceIds;
  vmDomainName = "win11-GPU"; #TODO: Make this dynamic based on VMs

  give-vfio-dGPU = pkgs.writeShellScriptBin "give-vfio-dgpu" ''
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

    # Stop NVIDIA services and unload modules
    echo "[HOOK] Stopping NVIDIA persistence daemon (if running)..."
    systemctl stop nvidia-persistenced.service 2>/dev/null || true

    # Unload NVIDIA modules in reverse order
    for module in nvidia_uvm nvidia_drm nvidia_modeset nvidia i2c_nvidia_gpu; do
      if lsmod | grep -q "^$module "; then
        echo "[HOOK] Unloading $module module..."
        modprobe -r $module || echo "[WARNING] Failed to unload $module, continuing anyway"
      fi
    done

    # Check if NVIDIA device is in use
    if [ -e /dev/nvidia0 ]; then
      echo "[HOOK] Checking if NVIDIA device is in use..."
      if ${getExe' pkgs.psmisc "fuser"} /dev/nvidia0 2>/dev/null; then
        echo "[ERROR] NVIDIA device is still in use by some process"
        exit 1
      fi
    fi

    # Load VFIO modules
    echo "[HOOK] Ensuring VFIO modules are loaded..."
    for module in vfio vfio-pci vfio_iommu_type1; do
      modprobe $module || echo "[ERROR] Failed to load $module module"
    done
    
    # Process each device ID from configuration
    ${lib.concatMapStrings (id: ''
      VENDOR_ID=$(echo "${id}" | cut -d':' -f1)
      DEVICE_ID=$(echo "${id}" | cut -d':' -f2)
      echo "[HOOK] Processing device: $VENDOR_ID:$DEVICE_ID"
    '') gpuDeviceIds}

    # Unbind GPU from current driver if bound
    unbind_from_current_driver "${gpuBusId}" "GPU" || {
      echo "[ERROR] Failed to unbind GPU from current driver"
      exit 1
    }
    
    # Check for audio device and unbind if needed
    # Look for both common NVIDIA audio device IDs (22ba, 1aef, etc.)
    if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}" ]; then
      echo "[HOOK] Found audio device at ${gpuAudioBusId}"
      unbind_from_current_driver "${gpuAudioBusId}" "audio device" || echo "[WARNING] Failed to unbind audio device"
    else
      echo "[WARNING] Audio device not found at ${gpuAudioBusId}, may cause issues"
    fi
    
    # Bind GPU to vfio-pci
    ${lib.concatMapStrings (id: ''
      BIND_VENDOR_ID=$(echo "${id}" | cut -d':' -f1)
      BIND_DEVICE_ID=$(echo "${id}" | cut -d':' -f2)
      bind_to_vfio "${gpuBusId}" "GPU" "$BIND_VENDOR_ID" "$BIND_DEVICE_ID" || {
        echo "[ERROR] Failed to bind GPU to vfio-pci"
        exit 1
      }
    '') gpuDeviceIds}
    
    # Find the vendor/product ID for the audio device
    AUDIO_VENDOR_ID="10de"  # NVIDIA
    # Check for known NVIDIA audio device IDs
    AUDIO_DEVICE_ID=""
    for known_id in "22ba" "1aef"; do
      ${lib.concatMapStrings (id: ''
        if [[ "${id}" == *"$known_id"* ]]; then
          AUDIO_DEVICE_ID="$known_id"
        fi
      '') gpuDeviceIds}
      if [ -n "$AUDIO_DEVICE_ID" ]; then
        break
      fi
    done

    # If we couldn't determine the audio ID, try to get it from lspci
    if [ -z "$AUDIO_DEVICE_ID" ]; then
      AUDIO_DEVICE_ID=$(lspci -nn | grep "${gpuAudioBusId}" | grep -oE '\[[0-9a-f]{4}:[0-9a-f]{4}\]' | cut -d':' -f2 | tr -d '[] ')
      if [ -z "$AUDIO_DEVICE_ID" ]; then
        # Default to common ID as fallback
        AUDIO_DEVICE_ID="22ba"
      fi
    fi
    
    # Bind audio device to vfio-pci
    if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}" ]; then
      bind_to_vfio "${gpuAudioBusId}" "audio device" "$AUDIO_VENDOR_ID" "$AUDIO_DEVICE_ID" || {
        echo "[WARNING] Failed to bind audio device to vfio-pci, continuing anyway"
      }
    fi
    
    # Final verification
    echo "[HOOK] Verifying device bindings..."
    GPU_BOUND=false
    AUDIO_BOUND=false
    
    if is_using_driver "${gpuBusId}" "vfio-pci"; then
      GPU_BOUND=true
      echo "[HOOK] GPU successfully bound to vfio-pci"
    else
      echo "[ERROR] GPU not bound to vfio-pci"
    fi
    
    if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}" ]; then
      if is_using_driver "${gpuAudioBusId}" "vfio-pci"; then
        AUDIO_BOUND=true
        echo "[HOOK] Audio device successfully bound to vfio-pci"
      else
        echo "[WARNING] Audio device not bound to vfio-pci"
      fi
    fi
    
    if [ "$GPU_BOUND" = true ]; then
      echo "[SUCCESS] GPU successfully prepared for passthrough"
      exit 0
    else
      echo "[ERROR] Failed to prepare GPU for passthrough"
      exit 1
    fi
  '';
  
  give-host-dGPU = pkgs.writeShellScriptBin "give-host-dgpu" ''
    #!${pkgs.stdenv.shell}
    set -e # Exit immediately if a command exits with a non-zero status.
    
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
    
    # 1. Unbind devices from vfio-pci
    unbind_from_vfio "${gpuBusId}" "GPU"
    unbind_from_vfio "${gpuAudioBusId}" "audio device"
    sleep 1
    
    # 2. Load NVIDIA kernel modules in correct order
    echo "[INFO] Loading NVIDIA kernel modules..."
    
    # Load modules with proper error handling
    for module in i2c_nvidia_gpu nvidia nvidia_modeset nvidia_drm nvidia_uvm; do
      if ! lsmod | grep -q "^$module "; then
        modprobe $module 2>/dev/null || echo "[WARN] Module $module failed to load"
      fi
    done
    
    # Check if nvidia module loaded successfully
    if ! lsmod | grep -q "^nvidia "; then
      echo "[ERROR] Failed to load NVIDIA driver. Is the module built for this kernel?"
      exit 1
    fi
    
    echo "[INFO] NVIDIA driver loaded successfully"
    
    # 3. Bind GPU devices to their drivers
    echo "[INFO] Binding devices to appropriate drivers..."
    
    # Bind GPU to nvidia driver
    if [ -d "/sys/bus/pci/drivers/nvidia" ]; then
      ${lib.concatMapStrings (id: ''                
        VENDOR_ID=$(echo "${id}" | cut -d':' -f1)
        DEVICE_ID=$(echo "${id}" | cut -d':' -f2)
        bind_device "${gpuBusId}" "nvidia" "GPU" "$VENDOR_ID" "$DEVICE_ID"
      '') gpuDeviceIds}
    else
      echo "[ERROR] NVIDIA driver directory not found"
      exit 1
    fi
    
    # Ensure snd_hda_intel module is loaded before binding audio device
    echo "[INFO] Ensuring snd_hda_intel module is loaded..."
    if ! lsmod | grep -q "^snd_hda_intel "; then
      modprobe snd_hda_intel 2>/dev/null || {
        echo "[WARN] Failed to load snd_hda_intel module, attempting to continue anyway"
      }
    fi
    
    # Bind audio device to snd_hda_intel
    if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}" ]; then
      AUDIO_VENDOR_ID=$(cat "/sys/bus/pci/devices/${gpuAudioBusId}/vendor" 2>/dev/null | sed 's/0x//')
      AUDIO_DEVICE_ID=$(cat "/sys/bus/pci/devices/${gpuAudioBusId}/device" 2>/dev/null | sed 's/0x//')
      
      # Try multiple binding attempts for the audio device
      for attempt in {1..3}; do
        echo "[INFO] Binding attempt $attempt for audio device..."
        if bind_device "${gpuAudioBusId}" "snd_hda_intel" "audio device" "$AUDIO_VENDOR_ID" "$AUDIO_DEVICE_ID"; then
          break
        fi
        # Small delay between attempts
        sleep 1
      done
    else
      echo "[INFO] No audio device found at ${gpuAudioBusId}"
    fi
    
    # 4. Final status check
    echo "[INFO] Device binding status:"
    GPU_DRIVER=$(basename $(readlink -f /sys/bus/pci/devices/${gpuBusId}/driver 2>/dev/null || echo "none"))
    AUDIO_DRIVER=$(basename $(readlink -f /sys/bus/pci/devices/${gpuAudioBusId}/driver 2>/dev/null || echo "none"))
    
    echo "[INFO] GPU driver: $GPU_DRIVER"
    echo "[INFO] Audio driver: $AUDIO_DRIVER"
    
    if [ "$GPU_DRIVER" = "nvidia" ]; then
      echo "[SUCCESS] GPU successfully returned to host"
    else
      echo "[WARNING] GPU may not be properly bound to nvidia driver"
    fi
    
    if [ "$AUDIO_DRIVER" = "snd_hda_intel" ]; then
      echo "[SUCCESS] Audio device successfully bound to snd_hda_intel"
    else
      echo "[WARNING] Audio device binding failed, manual intervention may be required"
      
      # Try a more aggressive approach if previous methods failed
      if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}" ] && [ "$AUDIO_DRIVER" != "snd_hda_intel" ]; then
        echo "[INFO] Attempting alternative binding method for audio device..."
        # Force remove from current driver if bound to something else
        if [ -e "/sys/bus/pci/devices/${gpuAudioBusId}/driver" ]; then
          CURRENT_DRIVER=$(basename $(readlink -f /sys/bus/pci/devices/${gpuAudioBusId}/driver 2>/dev/null))
          echo "[INFO] Unbinding from current driver: $CURRENT_DRIVER"
          echo "${gpuAudioBusId}" > "/sys/bus/pci/devices/${gpuAudioBusId}/driver/unbind" 2>/dev/null || true
        fi
        
        # Try direct binding again after forced unbind
        echo "${gpuAudioBusId}" > "/sys/bus/pci/drivers/snd_hda_intel/bind" 2>/dev/null || true
        
        # Final check
        FINAL_AUDIO_DRIVER=$(basename $(readlink -f /sys/bus/pci/devices/${gpuAudioBusId}/driver 2>/dev/null || echo "none"))
        if [ "$FINAL_AUDIO_DRIVER" = "snd_hda_intel" ]; then
          echo "[SUCCESS] Audio device bound to snd_hda_intel after alternative method"
        fi
      fi
    fi
  '';
  
  virsh-check-usb = pkgs.writeShellScriptBin "virsh-check-usb" ''
    #!${pkgs.stdenv.shell}

    usb_names=( $(${pkgs.usbutils}/bin/lsusb | cut -d' ' -f7-) )
    usb_ports=( $(${pkgs.usbutils}/bin/lsusb | cut -d' ' -f6) )

    arr=( $(virsh dumpxml ${vmDomainName} |
        xmlstarlet sel -t -m "/domain/devices/hostdev [@type='usb']" -v "source/vendor/@id" -o ":" -v "source/product/@id" -nl |
        sed -e 's/0x\([0-9a-f]*\)/\1/g') )

    i=1
    for usb in ''${arr[@]}; do
      $(${pkgs.usbutils}/bin/lsusb | grep -q $usb) || {
        echo "USB device $usb not connected right now, removing..."
        vendor=$(echo $usb | cut -d':' -f1)
        product=$(echo $usb | cut -d':' -f2)
        EDITOR="virsh dumpxml ${vmDomainName} | xmlstarlet ed -O -d \"/domain/devices/hostdev[source/vendor/@id='0x$vendor'][source/product/@id='0x$product']\" > " virsh edit win10
      }
    done
  '';

  virsh-detach-usb = pkgs.writeShellScriptBin "virsh-detach-usb" ''
    #!${pkgs.stdenv.shell}

    usb_names=( $(lsusb | cut -d' ' -f7-) )
    usb_ports=( $(lsusb | cut -d' ' -f6) )

    arr=( $(virsh dumpxml ${vmDomainName} |
    xmlstarlet sel -t -m "/domain/devices/hostdev [@type='usb']" -v "source/vendor/@id" -o ":" -v "source/product/@id" -nl |
    sed -e 's/0x\([0-9a-f]*\)/\1/g') )

    i=1
    for usb in ''${arr[@]}; do
      res=$(lsusb|grep $usb|cut -d' ' -f7-)
      echo "$i) $res ($usb)"
      ((i++))
    done

    read chosenidx
    ((chosenidx--))

    chosen_ports=''${arr[$chosenidx]}
    chosen_vendor=$(echo $chosen_ports|cut -d':' -f1)
    chosen_id=$(echo $chosen_ports|cut -d':' -f2)

    virsh detach-device ${vmDomainName} /dev/stdin <<EOF
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source>
        <vendor id='0x$chosen_vendor'/>
        <product id='0x$chosen_id'/>
      </source>
    </hostdev>
    EOF
  '';

  virsh-attach-usb = pkgs.writeShellScriptBin "virsh-attach-usb" ''
    #!${pkgs.stdenv.shell}

    IFS=$'\n'
    usb_names=( $(${pkgs.usbutils}/bin/lsusb | cut -d' ' -f7-) )
    usb_ports=( $(${pkgs.usbutils}/bin/lsusb | cut -d' ' -f6) )

    i=1
    for n in "''${usb_names[@]}"; do
        echo "$i) $n (''${usb_ports[(($i-1))]})"
        ((i++))
    done

    read chosenidx
    ((chosenidx--))

    chosen_name=''${usb_names[$chosenidx]}
    chosen_ports=''${usb_ports[$chosenidx]}
    chosen_vendor=$(echo $chosen_ports|cut -d':' -f1)
    chosen_id=$(echo $chosen_ports|cut -d':' -f2)

    if virsh list --all | grep ${vmDomainName} | grep -q "stopped"; then
        echo "VM shutdown, using virt-xml"
        virt-xml ${vmDomainName} --add-device --hostdev $chosen_ports
    else
        echo "VM up and running, using attach-device"
        virt-xml ${vmDomainName} --add-device --hostdev $chosen_ports
        virsh attach-device ${vmDomainName} /dev/stdin <<EOF
    <hostdev mode='subsystem' type='usb' managed='yes'>
        <source>
            <vendor id='0x$chosen_vendor'/>
            <product id='0x$chosen_id'/>
          </source>
    </hostdev>
    EOF

    fi
  '';

in
{
  config = mkIf (cfg.enable && cfg.vfio.enable && cfg.vfio.mode == "dynamic") {
    # Ensure the hook scripts have the tools they need
    systemd.services.libvirtd.path = [ pkgs.bash ];
    environment.systemPackages = [
      give-vfio-dGPU
      give-host-dGPU
      virsh-check-usb
      virsh-detach-usb
      virsh-attach-usb
    ];

    virtualisation.libvirtd.hooks.qemu = {
      "win11-cpu-gpu-vfio-dispatcher" = pkgs.writeShellScript "win11-cpu-gpu-vfio-dispatcher" ''
                #!/usr/bin/env bash
                set -e

                VM_NAME="$1"
                COMMAND="$2"

                # For a specific VM, run scripts on start/stop
                if [ "$VM_NAME" == "win11-GPU" ]; then
                  if [ "$COMMAND" == "prepare" ]; then
        						${pkgs.coreutils-full}/bin/echo "preparing"
                    ${give-vfio-dGPU}/bin/give-vfio-dgpu
                    ${virsh-check-usb}/bin/virsh-check-usb
                  elif [ "$COMMAND" == "started" ]; then
                    ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-3,16-23
                    ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-3,16-23
                    ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-3,16-23
                  elif [ "$COMMAND" == "release" ]; then
                    ${give-host-dGPU}/bin/give-host-dgpu
                    ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-23
                    ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-23
                    ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-23
                  fi
                fi
      '';
    };
  };
}
