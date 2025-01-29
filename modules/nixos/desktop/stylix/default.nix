{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.stylix;
in
{
  options.${namespace}.desktop.stylix = {
    enable = mkBoolOpt false "Enable stylix dynamic theming";
    wallpaper = mkOpt types.str "desaturated-grey-flowers" "Set the system-wide default wallpaper";
  };

  config = mkIf cfg.enable {
    # Go to https://stylix.danth.me/options/nixos.html for more Stylix options
    stylix = {
      enable = true;
      homeManagerIntegration.followSystem = false;

      targets.nixvim = {
        enable = false;
        plugin = pkgs.base16-nvim;
        transparentBackground.main = true;
        transparentBackground.signColumn = true;
      };

      polarity = "dark"; # "light" || "dark" || "either"

      image = pkgs.spirenix.wallpapers.wallpapers.${cfg.wallpaper};

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
      };

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
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
        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
        sizes = {
          applications = 16;
          terminal = 18;
          desktop = 12;
          popups = 12;
        };
      };
    };
  };
}
