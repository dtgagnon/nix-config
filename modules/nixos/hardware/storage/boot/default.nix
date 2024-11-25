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
  imports = [
    ./bootloader.nix
    ./kernel.nix
  ];

  options.${namespace}.hardware.storage.boot = {
    enable = mkBoolOpt true "Whether to enable boot configuration";
    
    preset = mkOpt (types.enum ["desktop" "server" "minimal"]) "desktop" 
      "Preset configuration to use";
  };

  config = mkIf cfg.enable {
    ${namespace}.hardware.storage.boot = let
      p = cfg.preset;
    in {
      # Configure component options based on preset
      bootloader = mkIf (p == "desktop") {
        type = "systemd-boot";
        configLimit = 10;
        editor = false;
      };

      kernel = mkIf (p == "desktop") {
        modules = [ "kvm-intel" "xhci_pci" "ahci" "nvme" ];
        initrd.modules = [ "dm-snapshot" ];
      };
    };

    assertions = [{
      assertion = config.${namespace}.hardware.storage.enable;
      message = "Storage configuration must be enabled to use boot configuration";
    }];
  };
}
