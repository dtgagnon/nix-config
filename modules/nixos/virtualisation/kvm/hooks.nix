{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.virtualisation.kvm;

  vfioCfg = config.${namespace}.virtualisation.kvm.vfio;

  give-vm-dGPU = pkgs.writeShellScriptBin "give-vm-dgpu" ''
        		set -e
        		echo "[$(date)] Detaching GPU for VM use..." >> /tmp/vfio-hook.log
        		GPU_VIDEO="0000:01:00.0"
        		GPU_AUDIO="0000:01:00.1"

        		# Unbind from host drivers, ignoring errors if not bound
        		echo "$GPU_VIDEO" > /sys/bus/pci/drivers/nvidia/unbind 2>/dev/null || true
        		echo "$GPU_AUDIO" > /sys/bus/pci/drivers/snd_hda_intel/unbind 2>/dev/null || true

        		# Bind to vfio-pci
        		echo "$GPU_VIDEO" > /sys/bus/pci/drivers/vfio-pci/bind
        		echo "$GPU_AUDIO" > /sys/bus/pci/drivers/vfio-pci/bind
    	'';

  give-host-dGPU = pkgs.writeShellScriptBin "give-host-dgpu" ''
    		set -e
        echo "[$(date)] Attaching GPU to Host..." >> /tmp/vfio-hook.log
        GPU_VIDEO="0000:01:00.0"
        GPU_AUDIO="0000:01:00.1"

        # Unbind from vfio-pci
        echo "$GPU_VIDEO" > /sys/bus/pci/drivers/vfio-pci/unbind
        echo "$GPU_AUDIO" > /sys/bus/pci/drivers/vfio-pci/unbind

        # Remove and Rescan to let host reclaim devices
        echo 1 > /sys/bus/pci/devices/$GPU_VIDEO/remove
        echo 1 > /sys/bus/pci/devices/$GPU_AUDIO/remove
        sleep 1
        echo 1 > /sys/bus/pci/rescan
  '';
in
{
  config = mkIf (cfg.enable && vfioCfg.enable && vfioCfg.mode == "dynamic") {
    # Ensure the hook scripts have the tools they need
    # systemd.services.libvirtd.path = [ pkgs.bash ];

    virtualisation.libvirtd.hooks.qemu = {
      "win11-cpu-gpu-vfio-dispatcher" = pkgs.writeShellScript "win11-cpu-gpu-vfio-dispatcher" ''
        #!/usr/bin/env bash
        set -e

        VM_NAME="$1"
        COMMAND="$2"

        # For a specific VM, run scripts on start/stop
        if [ "$VM_NAME" == "win11-GPU" ]; then
          if [ "$COMMAND" == "prepare" ]; then
            ${give-vm-dGPU}/bin/give-vm-dgpu
          elif [ "$COMMAND" == "started" ]; then
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-3,16-23
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-3,16-23
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.slice AllowedCPUs=0-3,16-23
          elif [ "$COMMAND" == "release" ]; then
            ${give-host-dGPU}/bin/give-host-dgpu
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-23
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-23
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.slice AllowedCPUs=0-23
          fi
        fi
      '';
    };
  };
}
