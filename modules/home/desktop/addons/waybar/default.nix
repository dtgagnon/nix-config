{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.waybar;
in
{
  options.${namespace}.desktop.addons.waybar = {
    enable = mkBoolOpt false "Whether to enable Waybar in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.waybar ];

    spirenix.home.configFile."waybar/config".source = ./config;
    spirenix.home.configFile."waybar/style.css".source = ./style.css;
  };
}
