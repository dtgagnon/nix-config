{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.styling.stylix;

  core = config.spirenix.desktop.styling.core;
in
{
  options.${namespace}.desktop.styling.stylix = {
    enable = mkBoolOpt false "Enable stylix dynamic theming";
    wallpaper = mkOpt (types.nullOr types.package) null "Designate the name of the source image";
    polarity = mkOpt (types.str) "either" "Choose automatic theme polarity [`either`, `light`, `dark`]";
    override = mkOpt (types.attrsOf types.str) { } "Designate the base16 target to override";
    excludedTargets = mkOpt (types.listOf types.str) [ ] "Declare a list of targets to exclude from Stylix theming";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Go to https://stylix.danth.me/options/nixos.html for more Stylix options
      stylix = lib.mkDefault {
        enable = true;
        polarity = cfg.polarity;

        image = if (cfg.wallpaper == null) then core.wallpaper else cfg.wallpaper;
        imageScalingMode = "stretch";

        override =
          { }
          // cfg.override;

        cursor = {
          package = core.cursor.package;
          name = core.cursor.name;
          size = core.cursor.size;
        };

        fonts = {
          monospace = {
            package = core.fonts.monospace.package;
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
          terminal = 0.8;
          desktop = 0.8;
          popups = 0.8;
        };

        targets =
          lib.foldl'
            (
              acc: target:
                acc
                // {
                  ${target}.enable = false;
                }
            )
            {
              #TODO: Remove gtk enbable from here; test for impact to theming. Suspect unnecessary
              gtk = {
                enable = true;
                # extraCss = builtins.readFile ../gtk/gtk.css;
              };
            }
            cfg.excludedTargets;
      };
    })
    (mkIf (core.theme != null) {
      stylix.base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/${core.theme}.yaml";
    })
  ];
}
