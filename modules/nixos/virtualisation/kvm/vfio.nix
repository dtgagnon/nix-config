{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types optionalString concatStringsSep;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.virtualisation.kvm.vfio;
  kvmCfg = config.${namespace}.virtualisation;
  user = config.${namespace}.user;
in
{
  options.${namespace}.virtualisation.vfio = {
    enable = mkBoolOpt false "Enable VFIO Configuration";
    mode = mkOpt (types.enum [ "static" "dynamic" ]) "dynamic" "dynamic: GPU is bound to host at boot. Hooks are required. static: GPU is bound to vfio-pci at boot";
    deviceIds = mkOpt (types.listOf types.str) [ ] "The hardware vendor:product IDs to pass through to the VM";
    # blacklistNvidia = mkBoolOpt false "Add Nvidia GPU modules to blacklist";
    # passGpuAtBoot = mkBoolOpt false "Pass the GPU to VFIO at boot";

    # disableEFIfb = mkOpt types.bool false "Disables the usage of the EFI framebuffer on boot.";
    # ignoreMSRs = mkBoolOpt false "Disable kvm guest access to model-specific registers";
    # disablePCIeASPM = mkBoolOpt false "Disable PCIe Active-State Power Management";
  };

  config = mkIf (kvmCfg.enable && cfg.enable) {
    boot.kernelParams = [
      "${kvmCfg.gpu.iGPU}_iommu=on" # Assumes iGPU platform for IOMMU
      "iommu=pt"
      "video=efifb:off"
    ];

    # === Static Passthrough Configuration === #
    # Only applies if mode is set to "static"
    boot.blacklistedKernelModules = mkIf (cfg.mode == "static") [ "nvidia" "nouveau" ];
    boot.initrd.kernelModules = mkIf (cfg.mode == "static") [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
    boot.extraModprobeConfig = mkIf (cfg.mode == "static") ''
      options vfio-pci ids=${concatStringsSep "," cfg.deviceIds}
    '';

    # === Dynamic Passthrough Configuration === #
    # Only applies if mode is set to "dynamic"
    boot.initrd.availableKernelModules = mkIf (cfg.mode == "dynamic") [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="${user.name}", GROUP="qemu-libvirtd", MODE="0660"
  '';

  boot = {
    initrd.kernelModules = mkIf cfg.passGpuAtBoot [
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio"
    ];

    kernelModules = [
      "vhost-net"
      "kvmfr"
    ];

    kernelParams = [
      "${kvmCfg.platform}_iommu=on"
      "iommu=pt"
      "video=efifb:off"
    ];
    #NOTE: belongs above, testing without
    # "pcie_aspm=off"

    extraModprobeConfig = ''
      ${optionalString cfg.passGpuAtBoot "options vfio-pci ids=${concatStringsSep "," cfg.deviceIds}"}
      options kvm ignore_msrs=1
      options kvm report_ignored_msrs=0
      options kvmfr static_size_mb=64
      softdep nvidia pre: vfio-pci
    '';

    extraModulePackages = [ config.boot.kernelPackages.kvmfr ];

    blacklistedKernelModules = mkIf cfg.blacklistNvidia [ "nvidia" "nouveau" ];
  };
};
}
