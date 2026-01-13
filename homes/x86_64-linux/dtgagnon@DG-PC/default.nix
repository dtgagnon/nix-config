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
      yell = enabled;
      zen = enabled;
    };

    cli = {
      bat = enabled;
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
        sysbar.quickshell.premade = "noctalia-shell";
        rofi.style = "slim";
        weylus = enabled;
      };
      hyprland = {
        enable = true;
        monitors = [ ];
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
          # theme = "nord";
          wallpaper = pkgs.spirenix.wallpapers.wallpapers.electric-fractal-filament-wide-rust-white-blue;
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
      copyparty-client = enabled;
      syncthing = enabled;
    };
  };

  sops.secrets = {
    anthropic_api = { };
    deepseek_api = { };
    dtgagnon-copyparty-pass = { };
    moonshot_api = { };
    odoo_api_key = { };
    openai_api = { };
    openrouter_api = { };
    ref_api = { };
    wallhaven_api = { };
  };

  home.stateVersion = "24.11";
}
