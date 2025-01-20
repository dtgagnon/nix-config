{ lib
, pkgs
, config
, osConfig ? { }
, format ? "unknown"
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled mkRGBA;
  inherit (config.lib.stylix) colors;
in
{
  spirenix = {
    user = {
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };

    apps = {
      office.okular-pdf = enabled;
      terminals = {
        ghostty = {
          enable = true;
          dark-theme = "catppuccin-frappe";
          light-theme = "catppuccin-latte";
        };
      };
      zen = enabled;
    };

    cli = {
      bat = enabled;
      bottom = enabled;
      broot = enabled;
      carapace = enabled;
      direnv = enabled;
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      git = enabled;
      neovim = enabled;
      network-tools = enabled;
      shells.nushell = enabled;
      ssh = enabled;
      yazi = enabled;
      zoxide = enabled;
    };

    desktop = {
      styling.core = {
        enable = true;
        cursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Ice";
          size = 24;
        };
        theme = "catppuccin-frappe";
        wallpaper = pkgs.spirenix.wallpapers.wallpapers.catppuccin.flying-comets-clouds;
      };
      styling.stylix = {
        enable = true;
        polarity = "dark";
      };

      styling.wallpapers = enabled;
    };

    services.syncthing = enabled;
  };

  home.stateVersion = "24.11";
}
