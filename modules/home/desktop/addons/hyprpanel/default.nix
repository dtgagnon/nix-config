{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.hyprpanel;
in
{
  options.${namespace}.desktop.addons.hyprpanel = {
    enable = mkBoolOpt false "Whether to enable hyprpanel.";
  };

  config = mkIf cfg.enable {
    programs.hyprpanel = {
      enable = true;
      systemd.enable = true;
      hyprland.enable = true;
      overwrite.enable = true;
    };
  };
}
