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

      image =
        if cfg.wallpaper == null then pkgs.spirenix.wallpapers.nord-rainbow-dark-nix else cfg.wallpaper;
      imageScalingMode = "stretch";

      base16Scheme = mkIf (
        cfg.wallpaper == null
      ) "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";

      override = {
        base00 = "#9DA18F";
        base0B = "${config.stylix.base16Scheme.base05}";
      } // cfg.override;

      fonts = {
        monospace = {
          package = pkgs.nerdfonts.override { fonts = [ 
            "Iosevka"
            "JetBrainsMono"
          ]; };
          name = "JetBrainsMono Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
        sizes = {
          applications = 12;
          terminal = 15;
          desktop = 10;
          popups = 10;
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
