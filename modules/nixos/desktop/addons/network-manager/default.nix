{ 
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.network-manager;
in
{
  options.${namespace}.desktop.addons.network-manager = {
      enable = mkBoolOpt false "Enable NetworkManager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  };
}