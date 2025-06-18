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
      gimp = enabled;
      inkscape = enabled;
      looking-glass-client = enabled;
      obsidian = enabled;
      office.okular-pdf = enabled;
      # super-productivity = enabled;
      terminals = {
        ghostty = {
          enable = true;
          dark-theme = "Everforest Dark - Hard";
          light-theme = "Everforest Dark - Hard";
        };
      };
      todoist = enabled;
      vscode = enabled;
      windsurf = enabled;
      zen = enabled;
    };

    cli = {
      bat = enabled;
      bottom = enabled;
      broot = enabled;
      carapace = enabled;
      claude-code = enabled;
      direnv = enabled;
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      git = enabled;
      neovim = enabled;
      network-tools = enabled;
      shells = { nushell = enabled; zsh = enabled; };
      ssh = enabled;
      yazi = enabled;
      zoxide = enabled;
    };

    desktop = {
      addons = {
        hellwal = enabled;
        kde-connect = enabled;
        weylus = enabled;
      };
      hyprland = {
        enable = true;
        monitors = [
          "DP-1,3440x1440@144,0x0,1"
        ];
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
          # theme = "everforest";
          wallpaper = pkgs.spirenix.wallpapers.wallpapers.hazy-purple-orange-sunset-palmtrees;
        };
        stylix = {
          enable = true;
          polarity = "dark";
        };
        wallpapers-dir = enabled;
      };
    };

    security.sops-nix = enabled;

    services = {
      activity-watch = enabled;
      syncthing = enabled;
    };
  };

  home.stateVersion = "24.11";
}
