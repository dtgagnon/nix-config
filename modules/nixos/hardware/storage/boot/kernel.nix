{
  lib,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.storage.boot;
in {
  options.${namespace}.hardware.storage.boot = {
    kernel = {
      modules = mkOpt (types.listOf types.str) [
        "kvm-intel"
      ] "List of kernel modules to load";
      
      initrd = {
        enable = mkBoolOpt true "Whether to enable initrd configuration";
        modules = mkOpt (types.listOf types.str) [ 
          "dm-snapshot" 
        ] "List of initrd modules";
        availableKernelModules = mkOpt (types.listOf types.str) [
          "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod"
        ] "List of kernel modules available in initrd";
      };

      extraModulePackages = mkOpt (types.listOf types.package) [ ] 
        "List of additional kernel module packages";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      kernelModules = cfg.kernel.modules;
      extraModulePackages = cfg.kernel.extraModulePackages;
      
      initrd = mkIf cfg.kernel.initrd.enable {
        kernelModules = cfg.kernel.initrd.modules;
        availableKernelModules = cfg.kernel.initrd.availableKernelModules;
      };
    };
  };
}
