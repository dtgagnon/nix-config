{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types length optionalString concatStringsSep;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.virtualisation.kvm.vfio;
  cfg-kvm = config.${namespace}.virtualisation.kvm;
  user = config.${namespace}.user;
in
{
  options.${namespace}.virtualisation.kvm.vfio = {
    enable = mkBoolOpt false "Enable VFIO Configuration";
    vfioIds = mkOpt (types.listOf types.str) [ ] "The hardware IDs to pass through to the VM";
    blacklistNvidia = mkBoolOpt false "Add Nvidia GPU modules to blacklist";
    passGpuAtBoot = mkBoolOpt false "Pass the GPU to VFIO at boot";

    # disableEFIfb = mkOpt types.bool false "Disables the usage of the EFI framebuffer on boot.";
    # ignoreMSRs = mkBoolOpt false "Disable kvm guest access to model-specific registers";
    # disablePCIeASPM = mkBoolOpt false "Disable PCIe Active-State Power Management";
  };

  config = mkIf (cfg-kvm.enable && cfg.enable) {
    services.udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="${user.name}", GROUP="qemu-libvirtd", MODE="0660"
    '';

    boot = {
      initrd.kernelModules = mkIf cfg.passGpuAtBoot [
        "vfio_pci"
        "vfio_iommu_type1"
        "vfio"
      ];

      initrd.availableKernelModules = mkIf (!cfg.passGpuAtBoot) [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];

      kernelModules = [
        "vhost-net"
        "kvmfr"
      ];

      kernelParams = [
        "${cfg-kvm.platform}_iommu=on"
        "iommu=pt"
        "video=efifb:off"
      ];
      #NOTE: belongs above, testing without
      # "pcie_aspm=off"

      extraModprobeConfig = ''
        ${optionalString cfg.passGpuAtBoot "options vfio-pci ids=${concatStringsSep "," cfg.vfioIds}"}
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
