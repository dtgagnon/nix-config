{
  lib,
  pkgs,
  config,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.stylix;
in
{
  options.${namespace}.desktop.stylix = {
    enable = mkBoolOpt false "Enable stylix dynamic theming";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.spirenix.wallpapers
      pkgs.bibata-cursors
    ];

    # Go to https://stylix.danth.me/options/nixos.html for more Stylix options
    stylix = {
      enable = true;
      polarity = "either"; # "light" || "dark" || "either"

      image = pkgs.spirenix.wallpapers.nord-rainbow-dark-nix-ultrawide;

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
    };
  };
}
