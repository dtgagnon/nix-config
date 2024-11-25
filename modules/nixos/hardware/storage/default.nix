{
  lib,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.hardware.storage;
in {
  imports = [
    ./disko.nix
    ./boot
  ];

  options.${namespace}.hardware.storage = {
    enable = mkBoolOpt true "Whether to enable storage configuration";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.enable -> config.${namespace}.hardware.storage.boot.enable;
      message = "Boot configuration must be enabled when storage is enabled";
    }];
  };
}
