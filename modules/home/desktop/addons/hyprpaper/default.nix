{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.hyprpaper;
in
{
  options.${namespace}.desktop.addons.hyprpaper = {
    enable = mkBoolOpt false "Whether to enable Hyprpaper in the desktop environment.";
    wallpaper = mkOpt (types.oneOf [ types.package types.path types.str ]) pkgs.spirenix.wallpapers "The wallpaper to use.";
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      # settings = {
      #   wallpaper = ", ${cfg.wallpaper}";
      # };
    };
  };
}
