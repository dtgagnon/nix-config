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
      targets.dgpu-host-ready = { description = "Target for services that need the dGPU on the host"; };
      paths.dgpu-host-ready = {
        description = "Monitor for dGPU being returned to host";
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
          Unit = "dgpu-host-ready.service";
          PathModified = "/var/lib/systemd/qemu-hooks-state";
        };
      };
      services = mkMerge [
        {
          libvirtd.path = [ pkgs.bash cfg.hooksPackage ];

          dgpu-host-ready = {
            description = "Check for dGPU on host and start or stop services";
            wantedBy = [ "multi-user.target" ];
            path = [ pkgs.coreutils pkgs.systemd ];
            serviceConfig = { Type = "oneshot"; };
            script = ''
              if [ -f /var/lib/systemd/qemu-hooks-state ] && [ "$(cat /var/lib/systemd/qemu-hooks-state)" = "0" ]; then
                echo "dGPU is on host, starting dgpu-host-ready.target"
                systemctl start dgpu-host-ready.target
              else
                echo "dGPU is not on the host, stopping dgpu-host-ready.target"
                systemctl stop dgpu-host-ready.target
              fi
            '';
          };

          give-host-dgpu-startup = {
            description = "Gives the host the dGPU after launching the desktop session";
            path = [
              cfg.hooksPackage
              pkgs.kmod
              pkgs.coreutils
              pkgs.systemd
            ];
            serviceConfig = {
              Type = "oneshot";
              User = "root";
              Group = "wheel";
              ExecStart = "${cfg.hooksPackage}/bin/give-host-dgpu";
            };
          };
        }

        (mkIf config.hardware.nvidia.nvidiaPersistenced {
          nvidia-persistenced = {
            after = mkForce [ ];
            wantedBy = mkForce [ "dgpu-host-ready.target" ];
            partOf = mkForce [ "dgpu-host-ready.target" ];
          };
        })
        (mkIf config.services.ollama.enable {
          ollama = {
            after = mkForce [ ];
            wantedBy = mkForce [ "dgpu-host-ready.target" ];
            partOf = [ "dgpu-host-ready.target" ];
          };
        })
      ];
    };
  };
}
