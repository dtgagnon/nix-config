{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf getExe';
  cfg = config.${namespace}.virtualisation.kvm;
  gpuBusId = config.${namespace}.hardware.gpu.dGPU.busId;
  gpuMfg = config.${namespace}.hardware.gpu.dGPU.mfg;
  gpuDeviceIds = config.${namespace}.hardware.gpu.dGPU.deviceIds;
  vmDomainName = "win11-GPU"; #TODO: Make this dynamic based on VMs

  give-vfio-dGPU = pkgs.writeShellScriptBin "give-vfio-dgpu"
    (if (gpuMfg == "amdgpu") then ''
              #!${pkgs.stdenv.shell}
              set -e
  
              if [ -d /sys/bus/pci/drivers/amdgpu/0000:${gpuBusId} ]; then
                echo 0000:${gpuBusId} > /sys/bus/pci/drivers/amdgpu/unbind
              fi
  
              # Binding to amdgpu resizes the BAR from 256MB to 4GB (on RX 570). This causes Windows
              # guests to fail initializing DirectX and macOS guests to hang during boot.
              # Setting the BAR size back to 256MB before starting the VM fixes these issues.
              echo 8 > /sys/bus/pci/devices/0000:${gpuBusId}/resource0_resize
  
              if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver)) != "vfio-pci" ]; then
                ${getExe' config.virtualisation.libvirtd.package "virsh"} nodedev-detach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpuBusId)}
              fi
    ''
    else if (gpuMfg == "nvidia") then ''
                #!${pkgs.stdenv.shell}
                set -e

                echo "[HOOK] Stopping NVIDIA persistence daemon (if running)..."
                systemctl stop nvidia-persistenced.service 2>/dev/null || true

                # Avoid in-use error when modeset is enabled
                # Check if modules exist before attempting to remove them
                lsmod | grep -q nvidia_uvm && modprobe -r nvidia_uvm
                lsmod | grep -q nvidia_drm && modprobe -r nvidia_drm
                lsmod | grep -q nvidia_modeset && modprobe -r nvidia_modeset
                lsmod | grep -q nvidia && modprobe -r nvidia
                lsmod | grep -q i2c_nvidia_gpu && modprobe -r i2c_nvidia_gpu

                # Only check if the device is in use if it actually exists
                if [ -e /dev/nvidia0 ]; then
                  echo "[HOOK] Checking if NVIDIA device is in use..."
                  ${getExe' pkgs.psmisc "fuser"} /dev/nvidia0 && exit 1
                fi

                # Load VFIO modules if they aren't already loaded
                echo "[HOOK] Ensuring VFIO modules are loaded..."
                modprobe vfio || echo "Failed to load vfio module"
                modprobe vfio-pci || echo "Failed to load vfio-pci module"
                modprobe vfio_iommu_type1 || echo "Failed to load vfio_iommu_type1 module"
                
                ${lib.concatMapStrings (id: ''                
                  VENDOR_ID=$(echo "${id}" | cut -d':' -f1)
                  DEVICE_ID=$(echo "${id}" | cut -d':' -f2)
                  echo "[HOOK] Processing GPU device: Vendor ID $VENDOR_ID, Device ID $DEVICE_ID"
                '') gpuDeviceIds}

                # Check if driver exists and is not vfio-pci
                if [ -e /sys/bus/pci/devices/0000:${gpuBusId}/driver ] && [ "$(basename $(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver))" != "vfio-pci" ]; then
                  echo "[HOOK] Detaching GPU from host driver..."
                  ${getExe' config.virtualisation.libvirtd.package "virsh"} nodedev-detach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpuBusId)}
                  
                  # Verify if virsh detached properly
                  if [ "$(basename $(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver 2>/dev/null))" != "vfio-pci" ]; then
                    echo "[HOOK] Virsh detach didn't work properly, trying manual method..."
                    
                    # First try to unbind if still bound
                    if [ -e /sys/bus/pci/devices/0000:${gpuBusId}/driver ]; then
                      echo "[HOOK] Unbinding GPU from current driver..."
                      echo "0000:${gpuBusId}" > /sys/bus/pci/drivers/$(basename $(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver))/unbind
                    fi
                    
                    # New IDs to vfio-pci - bind all device IDs from configuration
                    echo "[HOOK] Binding GPU to vfio-pci driver..."
                    ${lib.concatMapStrings (id: ''                
                      BIND_VENDOR_ID=$(echo "${id}" | cut -d':' -f1)
                      BIND_DEVICE_ID=$(echo "${id}" | cut -d':' -f2)
                      echo "[HOOK] Binding device: $BIND_VENDOR_ID $BIND_DEVICE_ID to vfio-pci"
                      echo "$BIND_VENDOR_ID $BIND_DEVICE_ID" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
                    '') gpuDeviceIds}
                    
                    # Check if bind succeeded - safer method
                    DRIVER_LINK=$(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver 2>/dev/null || echo "")
                    if [ -n "$DRIVER_LINK" ] && [ "$(basename $DRIVER_LINK 2>/dev/null)" = "vfio-pci" ]; then
                      echo "[HOOK] Successfully bound GPU to vfio-pci"
                    else
                      # Check both the GPU and audio device
                      AUDIO_DEVICE_BOUND=false
                      ${lib.concatMapStrings (id: ''                
                        if [[ "${id}" == *"22ba"* ]] && [ -e "/sys/bus/pci/devices/0000:01:00.1/driver" ]; then
                          if [ "$(basename $(readlink /sys/bus/pci/devices/0000:01:00.1/driver 2>/dev/null))" = "vfio-pci" ]; then
                            AUDIO_DEVICE_BOUND=true
                          fi
                        fi
                      '') gpuDeviceIds}
                      
                      if [ "$AUDIO_DEVICE_BOUND" = true ]; then
                        echo "[HOOK] Audio device is bound to vfio-pci, continuing"
                        echo "[HOOK] Successfully bound GPU components to vfio-pci"
                      else
                        echo "[HOOK] Failed to bind GPU to vfio-pci"
                        exit 1
                      fi
                    fi
                  else
                    echo "[HOOK] Successfully bound GPU to vfio-pci using virsh"
                  fi
                elif [ -e /sys/bus/pci/devices/0000:${gpuBusId}/driver ] && [ "$(basename $(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver))" = "vfio-pci" ]; then
                  echo "[HOOK] GPU already using vfio-pci driver"
                else
                  echo "[HOOK] GPU has no driver bound, binding directly to vfio-pci..."
                  ${lib.concatMapStrings (id: ''                
                    BIND_VENDOR_ID=$(echo "${id}" | cut -d':' -f1)
                    BIND_DEVICE_ID=$(echo "${id}" | cut -d':' -f2)
                    echo "[HOOK] Binding device: $BIND_VENDOR_ID $BIND_DEVICE_ID to vfio-pci"
                    echo "$BIND_VENDOR_ID $BIND_DEVICE_ID" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
                  '') gpuDeviceIds}
                  
                  echo "[HOOK] Binding primary GPU at 0000:${gpuBusId} to vfio-pci"
                  echo "0000:${gpuBusId}" > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || true
                  
                  # Force unbind/bind audio device if it exists
                  if [ -e /sys/bus/pci/devices/0000:01:00.1/driver ]; then
                    echo "[HOOK] Unbinding audio device from current driver"
                    current_audio_driver=$(basename $(readlink /sys/bus/pci/devices/0000:01:00.1/driver 2>/dev/null))
                    if [ -n "$current_audio_driver" ] && [ "$current_audio_driver" != "vfio-pci" ]; then
                      echo "0000:01:00.1" > /sys/bus/pci/drivers/$current_audio_driver/unbind 2>/dev/null || true
                      echo "[HOOK] Binding audio device to vfio-pci"
                      echo "0000:01:00.1" > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || true
                    fi
                  fi
                  
                  # Check if the GPU is using vfio-pci driver more safely
                  DRIVER_LINK=$(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver 2>/dev/null || echo "")
                  if [ -n "$DRIVER_LINK" ] && [ "$(basename $DRIVER_LINK 2>/dev/null)" = "vfio-pci" ]; then
                    echo "[HOOK] Successfully bound GPU to vfio-pci"
                  else
                    # Also need to check audio device separately since that's often bound separately
                    echo "[HOOK] Checking if audio device is properly bound..."
                    AUDIO_DEVICE_BOUND=false
                    ${lib.concatMapStrings (id: ''                
                      if [[ "${id}" == *"22ba"* ]] && [ -e "/sys/bus/pci/devices/0000:01:00.1/driver" ]; then
                        if [ "$(basename $(readlink /sys/bus/pci/devices/0000:01:00.1/driver 2>/dev/null))" = "vfio-pci" ]; then
                          AUDIO_DEVICE_BOUND=true
                        fi
                      fi
                    '') gpuDeviceIds}
                    
                    if [ "$AUDIO_DEVICE_BOUND" = true ]; then
                      echo "[HOOK] Audio device is bound to vfio-pci, continuing"
                      echo "[HOOK] Successfully bound GPU components to vfio-pci"
                    else
                      echo "[HOOK] Failed to bind GPU to vfio-pci"
                      exit 1
                    fi
                  fi
                fi
    ''
    else throw "Unsupported gpu: ${gpuMfg}"
  );
  
  give-host-dGPU = pkgs.writeShellScriptBin "give-host-dGPU" (
    if (gpuMfg == "amdgpu") then ''
      #!${pkgs.stdenv.shell}
      set -e
  
      if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver)) == "vfio-pci" ]; then
        ${getExe' config.virtualisation.libvirtd.package "virsh"} nodedev-reattach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpuBusId)}
      fi
    ''
    else if (gpuMfg == "nvidia") then ''
      #!${pkgs.stdenv.shell}
      set -e
  
      if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver)) == "vfio-pci" ]; then
        ${getExe' config.virtualisation.libvirtd.package "virsh"} nodedev-reattach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpuBusId)}
      fi
  
      # Check if modules exist before attempting to load them
      { modprobe i2c_nvidia_gpu; } 2>/dev/null || echo "Module i2c_nvidia_gpu not found"
      { modprobe nvidia; } 2>/dev/null || echo "Module nvidia not found"
      { modprobe nvidia_modeset; } 2>/dev/null || echo "Module nvidia_modeset not found"
      { modprobe nvidia_drm; } 2>/dev/null || echo "Module nvidia_drm not found"
      { modprobe nvidia_uvm; } 2>/dev/null || echo "Module nvidia_uvm not found"
  
      echo "[HOOK] Restarting NVIDIA persistence daemon (if needed)..."
      systemctl start nvidia-persistenced.service 2>/dev/null || true
    ''
    else throw "Unsupported gpu: ${gpuMfg}"
  );
  
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
