{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.storage.boot;
in
{
  options.${namespace}.hardware.storage.boot = {
    enable = mkBoolOpt false "Whether to enable boot configuration";

    preset = mkOpt
      (types.enum [
        "desktop"
        "server"
        "minimal"
      ]) "desktop" "Preset configuration to use";

    bootloader = {
      type = mkOpt (types.enum [ "systemd-boot" "grub" ]) "systemd-boot" "Type of bootloader to use";
      configLimit = mkOpt types.int 5 "Number of generations to keep";
      editor = mkBoolOpt false "Whether to enable bootloader editor";
    };

    kernel = {
      modules = mkOpt (types.listOf types.str) [ "kvm-intel" ] "List of kernel modules to load";
      params = mkOpt (types.listOf types.str) [ ] "List of kernel parameters to apply to kernel modules at boot";

      initrd = {
        enable = mkBoolOpt true "Whether to enable initrd configuration";
        forceLuks = mkBoolOpt false "Force LUKS support in initrd";
        modules = mkOpt (types.listOf types.str) [ "dm-snapshot" ] "List of initrd modules";
        availableKernelModules = mkOpt (types.listOf types.str) [
          "xhci_pci"
          "ahci"
          "nvme"
          "usb_storage"
          "usbhid"
          "sd_mod"
        ] "List of kernel modules available in initrd";
      };

      extraModulePackages = mkOpt (types.listOf types.package) [ ] "List of additional kernel module packages";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      loader = {
        efi.canTouchEfiVariables = true;

        systemd-boot = mkIf (cfg.bootloader.type == "systemd-boot") {
          enable = true;
          configurationLimit = cfg.bootloader.configLimit;
          consoleMode = lib.mkDefault "max";
          editor = cfg.bootloader.editor;
        };

        grub = mkIf (cfg.bootloader.type == "grub") {
          enable = true;
          device = "nodev";
          efiSupport = true;
          configurationLimit = cfg.bootloader.configLimit;
        };
      };

      kernelModules = cfg.kernel.modules;
      kernelParams = cfg.kernel.params;
      extraModulePackages = cfg.kernel.extraModulePackages;

      initrd = mkIf cfg.kernel.initrd.enable {
        luks.forceLuksSupportInInitrd = cfg.kernel.initrd.forceLuks;
        systemd.enable = true;
        systemd.emergencyAccess = true;
        kernelModules = cfg.kernel.initrd.modules;
        availableKernelModules = cfg.kernel.initrd.availableKernelModules;
      };
    };
  };
}
