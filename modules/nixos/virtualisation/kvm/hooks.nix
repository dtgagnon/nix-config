{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkOption types mkForce mkMerge;
  cfg = config.${namespace}.virtualisation.kvm;
  user = config.${namespace}.user;
in
{
  options.${namespace}.virtualisation.kvm = {
    hooksPackage = mkOption {
      description = "Bundled qemu-hooks";
      type = types.package;
      default = pkgs.callPackage (lib.snowfall.fs.get-file "packages/qemu-hooks/default.nix") {
        enablePersistencedStop = config.hardware.nvidia.nvidiaPersistenced;
        vmDomainName = "win11-GPU";
        gpuBusId = config.spirenix.hardware.gpu.dGPU.busId;
        dgpuDeviceIds = config.spirenix.hardware.gpu.dGPU.deviceIds;
      };
    };
  };

  config = mkIf (cfg.enable && cfg.vfio.enable && cfg.vfio.mode == "dynamic") {
    # Ensure the hook scripts have the tools they need
    environment.systemPackages = [
      cfg.hooksPackage
    ];

    virtualisation.libvirtd.hooks.qemu = {
      "qemu-hook-dispatcher" = "${cfg.hooksPackage}/bin/qemu-hook-dispatcher";
    };

    systemd = {
      targets.vfio-dgpu-available = { description = "Target for services that need the dGPU available on the host"; };
      paths.vfio-dgpu-state-monitor = {
        description = "Monitor for dGPU VFIO binding state changes";
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
          Unit = "vfio-dgpu-state-manager.service";
          PathModified = "/var/lib/systemd/vfio-dgpu-state";
        };
      };
      services = mkMerge [
        {
          libvirtd.path = [ pkgs.bash cfg.hooksPackage ];

          vfio-dgpu-state-manager = {
            description = "Manage dGPU availability state and dependent services";
            wantedBy = [ "multi-user.target" ];
            path = [ pkgs.coreutils pkgs.systemd ];
            serviceConfig = { Type = "oneshot"; };
            script = ''
              # Initialize state file if it doesn't exist
              # In dynamic mode, GPU is bound to nvidia driver at boot
              if [ ! -f /var/lib/systemd/vfio-dgpu-state ]; then
                echo "State file does not exist, initializing to 0 (dGPU available on host)"
                echo "0" > /var/lib/systemd/vfio-dgpu-state
              fi

              if [ "$(cat /var/lib/systemd/vfio-dgpu-state)" = "0" ]; then
                echo "dGPU is available on host, starting vfio-dgpu-available.target"
                systemctl start vfio-dgpu-available.target
              else
                echo "dGPU is not available on host, stopping vfio-dgpu-available.target"
                systemctl stop vfio-dgpu-available.target
              fi
            '';
          };
        }

        (mkIf config.hardware.nvidia.nvidiaPersistenced {
          nvidia-persistenced = {
            after = mkForce [ ];
            wantedBy = mkForce [ "vfio-dgpu-available.target" ];
            partOf = mkForce [ "vfio-dgpu-available.target" ];
          };
        })
        (mkIf config.services.ollama.enable {
          ollama = {
            after = mkForce [ ];
            wantedBy = mkForce [ "vfio-dgpu-available.target" ];
            partOf = [ "vfio-dgpu-available.target" ];
          };
        })
      ];
    };
  };
}
