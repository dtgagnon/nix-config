{ lib
, pkgs
, config
# , osConfig ? { }
# , format ? "unknown"
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
      discord = enabled;
      freecad = enabled;
      obsidian = enabled;
      office.okular-pdf = enabled;
      super-productivity = enabled;
      terminals = {
        ghostty = {
          enable = true;
          dark-theme = "catppuccin-frappe";
          light-theme = "catppuccin-latte";
        };
      };
      thunderbird = enabled;
      vscode = enabled;
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
      hyprland = {
        enable = true;
        monitors = [ "DP-5,3440x1440@144,0x0,1" ];
        extraConfig = ''
          general {
            col.active_border = ${mkRGBA { hex = "#${colors.base0D}"; alpha = 0.75; }}
            col.inactive_border = ${mkRGBA { hex = "#${colors.base03}"; alpha = 0.6; }}
          }
        '';
      };
      styling = {
        core = {
          enable = true;
          cursor = {
            package = pkgs.bibata-cursors;
            name = "Bibata-Modern-Ice";
            size = 24;
          };
          theme = "catppuccin-frappe";
          wallpaper = pkgs.spirenix.wallpapers.wallpapers.catppuccin.flying-comets-clouds;
        };
        stylix = {
          enable = true;
          polarity = "dark";
        };
        wallpapers-dir = enabled;
      };
    };

    services = {
      activity-watch = enabled;
      syncthing = enabled;
    };
  };

  home.stateVersion = "24.05";
}
