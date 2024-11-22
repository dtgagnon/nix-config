{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.waybar;
in
{
  options.${namespace}.desktop.addons.waybar = {
    enable = mkBoolOpt false "Whether to enable Waybar in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      style = mkDefault ./style.css;
    };

    xdg.configFile."waybar/config".source = ./config;
  };
}
