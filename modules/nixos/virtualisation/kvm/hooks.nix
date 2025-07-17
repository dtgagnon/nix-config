{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.${namespace}.virtualisation.kvm;
in
{
  options.${namespace}.virtualisation.kvm = {
    hooksPackage = mkOption {
      description = "Bundled qemu-hooks";
      type = types.package;
      default = pkgs.callPackage (lib.snowfall.fs.get-file "packages/qemu-hooks/default.nix") {
        enablePersistencedStop = config.hardware.nvidia.nvidiaPersistenced;
        enableOllamaStop = config.services.ollama.enable;
        vmDomainName = "win11-GPU";
        gpuBusId = config.spirenix.hardware.gpu.dGPU.busId;
        dgpuDeviceIds = config.spirenix.hardware.gpu.dGPU.deviceIds;
      };
    };
  };

  config = mkIf (cfg.enable && cfg.vfio.enable) {
    # Ensure the hook scripts have the tools they need
    systemd.services.libvirtd.path = [ pkgs.bash cfg.hooksPackage ];
    environment.systemPackages = [
      cfg.hooksPackage
    ];

    virtualisation.libvirtd.hooks.qemu = {
      "qemu-hook-dispatcher" = "${cfg.hooksPackage}/bin/qemu-hook-dispatcher";
    };
  };
}
