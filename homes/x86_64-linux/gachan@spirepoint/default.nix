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
      fullName = "Gina";
      email = "";
    };

    apps = {
      office.okular-pdf = enabled;
      terminals = {
        ghostty = {
          enable = true;
          dark-theme = "Everforest Dark - Hard";
          light-theme = "Everforest Dark - Hard";
        };
      };
      zen = enabled;
    };

    cli = {
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
        # theme = "brushtrees-dark";
        wallpaper = pkgs.spirenix.wallpapers.wallpapers.hazy-purple-orange-sunset-palmtrees;
      };
      styling.stylix = {
        enable = true;
        polarity = "either";
      };
    };
  };
  home.stateVersion = "24.11";
}
