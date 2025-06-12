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
                modprobe -r nvidia_uvm
                modprobe -r nvidia_drm
                modprobe -r nvidia_modeset
                modprobe -r nvidia
                modprobe -r i2x_nvidia_gpu

                # Avoid detaching the GPU if it's in use
                #TODO: Kill processes with --kill?
                ${getExe' pkgs.psmisc "fuser"} /dev/nvidia0 && exit 1

                if [ $(basename $(readlink /sys/bus/pci/devices/0000:${gpuBusId}/driver)) != "vfio-pci" ]; then
                  ${getExe' config.virtualisation.libvirtd.package "virsh"} nodedev-detach pci_0000_${(lib.replaceStrings [":" "."] ["_" "_"] gpuBusId)}
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

      modprobe i2c_nvidia_gpu
      modprobe nvidia
      modprobe nvidia_modeset
      modprobe nvidia_drm
      modprobe nvidia_uvm

      echo "[HOOK] Restarting NVIDIA persistence daemon (if needed)..."
      systemctl start nvidia-persistenced.service 2>/dev/null || true
    ''
    else throw "Unsupported gpu: ${gpuMfg}"
  );
in
{
  config = mkIf (cfg.enable && cfg.vfio.enable && cfg.vfio.mode == "dynamic") {
    # Ensure the hook scripts have the tools they need
    systemd.services.libvirtd.path = [ pkgs.bash ];
    environment.systemPackages = [
      give-vfio-dGPU
      give-host-dGPU
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
