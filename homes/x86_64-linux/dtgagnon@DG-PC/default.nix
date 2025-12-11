{ lib
, pkgs
, config
, # , osConfig ? { }
  # , format ? "unknown"
  namespace
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
      antigravity = enabled;
      discord = enabled;
      element = enabled;
      inkscape = enabled;
      jellyfin-client = enabled;
      kiro = enabled;
      looking-glass-client = enabled;
      music-player = {
        enable = true;
        player = "rmcp";
      };
      obsidian = enabled;
      office = {
        libreoffice = enabled;
        okular-pdf = enabled;
      };
      proton-cloud = enabled;
      # super-productivity = enabled;
      terminals.ghostty = {
        enable = true;
        trail = null;
      };
      thunderbird = enabled;
      todoist = enabled;
      # vscode = enabled;
      zen = enabled;
    };

    cli = {
      # aider = enabled;
      bat = enabled;
      bottom = enabled;
      broot = enabled;
      carapace = enabled;
      claude-code = enabled;
      codex = enabled;
      direnv = enabled;
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      gemini-cli = enabled;
      git = enabled;
      neovim = enabled;
      network-tools = enabled;
      opencode = enabled;
      shells = {
        nushell = enabled;
        zsh = enabled;
      };
      ssh = {
        enable = true;
        extraIdentityFiles = [ "~/.ssh/oranix" ];
      };
      web-browser = enabled;
      yazi = enabled;
      zoxide = enabled;
    };

    desktop = {
      addons = {
        hellwal = enabled;
        kde-connect = enabled;
        rofi.style = "slim";
        weylus = enabled;
      };
      hyprland = {
        enable = true;
        monitors = [
          "DP-1,7680x2160@60,0x0,1.25"
          "HDMI-A-5, disable"
        ];
        extraConfig = ''
          general {
            col.active_border = ${
              mkRGBA {
                hex = "#${colors.base0D}";
                alpha = 0.75;
              }
            }
            col.inactive_border = ${
              mkRGBA {
                hex = "#${colors.base03}";
                alpha = 0.6;
              }
            }
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
          theme = "nord";
          wallpaper = pkgs.spirenix.wallpapers.wallpapers.flat-blue-mountains;
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

  sops.secrets = {
    anthropic_api = { };
    deepseek_api = { };
    moonshot_api = { };
    odoo_api_key = { };
    openai_api = { };
    openrouter_api = { };
    ref_api = { };
  };

  home.stateVersion = "24.11";
}
