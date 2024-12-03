{
  lib,
  pkgs,
  config,
  inputs,
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
    wallpaper = mkOpt (types.nullOr types.package) pkgs.spirenix.wallpapers.painted-green-mountains "Designate the name of the source image";
    excludedTargets = mkOpt (types.listOf types.str) [ ] "Declare a list of targets to exclude from Stylix theming";
  };

  config = mkIf cfg.enable {
    spirenix.desktop.styling.wallpapers = enabled;
    # Go to https://stylix.danth.me/options/nixos.html for more Stylix options
    stylix = {
      enable = true;
      image = cfg.wallpaper;

      # base16Scheme = lib.mkIf (cfg.wallpaper == null) "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";

      fonts = {
        monospace = {
          package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
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
        terminal = 1.0;
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
