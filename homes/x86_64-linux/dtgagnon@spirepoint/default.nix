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
      # direnv = enabled;
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
      hyprland = {
        enable = true;
        monitors = [ ",1920x1080@60,0x0,1" ];
        extraConfig = ''
          general {
            col.active_border = ${mkRGBA { hex = "#${colors.base0D}"; alpha = 0.75; }}
            col.inactive_border = ${mkRGBA { hex = "#${colors.base03}"; alpha = 0.6; }}
          }
        '';
      };
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
