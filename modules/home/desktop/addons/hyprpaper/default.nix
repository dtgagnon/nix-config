{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.hyprpaper;
in
{
  options.${namespace}.desktop.addons.hyprpaper = {
    enable = mkBoolOpt false "Whether to enable Hyprpaper in the desktop environment.";
    wallpaper = mkOpt (types.oneOf [ types.package types.path types.str ]) pkgs.spirenix.wallpapers.wallpapers "The wallpaper to use.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.hyprpaper = {
        enable = true;
      };
    })
    (mkIf (!cfg.enable) {
      # Prevent stylix's Hyprland module from auto-enabling hyprpaper.
      # Without this, stylix.targets.hyprland.hyprpaper.enable defaults to true
      # when stylix.image is set, which causes the Hyprland target to set
      # services.hyprpaper.enable = true — bypassing this module entirely.
      stylix.targets.hyprland.hyprpaper.enable = false;
    })
  ];
}
