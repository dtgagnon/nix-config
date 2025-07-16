{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf getExe' replaceStrings optionalString;
  inherit (lib.lists) head last;
  cfg = config.${namespace}.virtualisation.kvm;
  qemu-hooks = pkgs.callPackage (lib.snowfall.fs.get-file "packages/qemu-hooks/default.nix") {
    enablePersistencedStop = config.hardware.nvidia.nvidiaPersistenced;
    enableOllamaStop = config.services.ollama.enable;
    vmDomainName = "win11-GPU";
    gpuBusId = config.spirenix.hardware.gpu.dGPU.busId;
    dgpuDeviceIds = config.spirenix.hardware.gpu.dGPU.deviceIds;
  };
in
{
  options.${namespace}.virtualisation.kvm = {
    hooksPackage = mkOpt types.package qemu-hooks "Bundled qemu-hooks";
  };

  config = mkIf (cfg.enable && cfg.vfio.enable) {
    # Ensure the hook scripts have the tools they need
    systemd.services.libvirtd.path = [ pkgs.bash cfg.hooksPackage ];
    environment.systemPackages = [
      cfg.hooksPackage
    ];

    virtualisation.libvirtd.hooks.qemu."qemu-hook-dispatcher" = "${cfg.hooksPackage}/bin/qemu-hook-dispatcher";
  };
}
