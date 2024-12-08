{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types foldl';
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled;
  cfg = config.${namespace}.desktop.styling.stylix;

  core = config.spirenix.desktop.styling.core;
in
{
  options.${namespace}.desktop.styling.stylix = {
    enable = mkBoolOpt false "Enable stylix dynamic theming";
    wallpaper = mkOpt (types.nullOr types.package) null "Designate the name of the source image";
    override = mkOpt (types.attrsOf types.str) { } "Designate the base16 target to override";
    excludedTargets =
      mkOpt (types.listOf types.str) [ ]
        "Declare a list of targets to exclude from Stylix theming";
  };

  config = mkIf cfg.enable {
    spirenix.desktop.styling.wallpapers = enabled;
    # Go to https://stylix.danth.me/options/nixos.html for more Stylix options
    stylix = {
      enable = true;

      image = if (cfg.wallpaper == null) then core.wallpaper else cfg.wallpaper;
      imageScalingMode = "stretch";

      base16Scheme = mkIf (core.theme != null) "${pkgs.base16-schemes}/share/themes/${core.theme}.yaml";

      override = {
      } // cfg.override;

      cursor = {
        package = core.cursor.package;
        name = core.cursor.name;
        size = core.cursor.size;
      };

      fonts = {
        monospace = {
          package = pkgs.nerdfonts.override { fonts = [ 
            core.fonts.monospace.nerdfont
            "Iosevka"
          ]; };
          name = core.fonts.monospace.name;
        };
        sansSerif = {
          package = core.fonts.sansSerif.package;
          name = core.fonts.sansSerif.name;
        };
        serif = {
          package = core.fonts.serif.package;
          name = core.fonts.serif.name;
        };
        sizes = {
          applications = core.fonts.sizes.applications;
          terminal = core.fonts.sizes.terminal;
          desktop = core.fonts.sizes.desktop;
          popups = core.fonts.sizes.popups;
        };
      };

      opacity = {
        applications = 1.0;
        terminal = 0.75;
        desktop = 1.0;
        popups = 1.0;
      };

      targets = foldl' (
        acc: target:
        acc
        // {
          ${target}.enable = false;
        }
      ) { } cfg.excludedTargets;
    };
  };
}
