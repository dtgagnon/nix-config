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
    bootloader = {
      type = mkOpt (types.enum ["systemd-boot" "grub"]) "systemd-boot" 
        "Type of bootloader to use";
      configLimit = mkOpt types.int 10 
        "Number of generations to keep";
      editor = mkBoolOpt false 
        "Whether to enable bootloader editor";
    };
  };

  config = mkIf cfg.enable {
    boot.loader = {
      efi.canTouchEfiVariables = true;

      systemd-boot = mkIf (cfg.bootloader.type == "systemd-boot") {
        enable = true;
        configurationLimit = cfg.bootloader.configLimit;
        editor = cfg.bootloader.editor;
      };

      grub = mkIf (cfg.bootloader.type == "grub") {
        enable = true;
        device = "nodev";
        efiSupport = true;
        configurationLimit = cfg.bootloader.configLimit;
      };
    };
  };
}
