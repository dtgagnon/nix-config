{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types foldl';
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.stylix;
  wallpaperPath = ../../../../packages/wallpapers/wallpapers;
in
{
  options.${namespace}.desktop.stylix = {
    enable = mkBoolOpt false "Enable stylix dynamic theming";
    excludedTargets = mkOpt (types.listOf types.str) [ ] "Declare a list of targets to exclude from Stylix theming";
  };

  config = mkIf cfg.enable {

    # Go to https://stylix.danth.me/options/nixos.html for more Stylix options
    stylix = {
      enable = true;
      polarity = "dark"; # "light" || "dark" || "either"

      image = "${wallpaperPath}"/nix-wallpaper-gear.png;
      # base16Scheme = (mkIf cfg.themeSource == "base16") "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
      # base16Scheme = {
      #   base00 = "";
      #   base01 = "";
      #   base02 = "";
      #   base03 = "";
      #   base04 = "";
      #   base05 = "";
      #   base06 = "";
      #   base07 = "";
      #   base08 = "";
      #   base09 = "";
      #   base0A = "";
      #   base0B = "";
      #   base0C = "";
      #   base0D = "";
      #   base0E = "";
      #   base0F = "";
      # };

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern_Ice";
      };

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

      # targets = foldl'
      #   (acc: target: acc // {
      #     ${target}.enable = false;
      #   })
      #   { }
      #   cfg.excludedTargets;
    };
  };
}
