{ lib
, pkgs
, config
, # , osConfig ? { }
  # , format ? "unknown"
  namespace
, ...
}:
let
  inherit (lib) optionalString;
  inherit (lib.${namespace}) enabled mkRGBA;
  stylixEnabled = config.stylix.enable or false;
  colors = if stylixEnabled then config.lib.stylix.colors else { };
in
{
  spirenix = {
    user = {
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };

    # Personal directories specific to dtgagnon
    preservation.directories = [
      "Games"
      "myVMs"
      "nix-config"
      "proj"
      "vfio-vm-info"
    ];

    apps = {
      aerc = enabled;
      antigravity = enabled;
      discord = enabled;
      element = enabled;
      freecad = enabled;
      inkscape = enabled;
      jellyfin-client = enabled;
      looking-glass-client = enabled;
      music-player = {
        enable = true;
        player = "rmpc";
      };
      obsidian = enabled;
      office = {
        libreoffice = {
          enable = true;
          mcpExtension = true;
        };
        okular-pdf = enabled;
      };
      proton-cloud = enabled;
      # super-productivity = enabled;
      terminals.ghostty = {
        enable = true;
        trail = null;
      };
      todoist = enabled;
      yell = enabled;
      zen = {
        enable = true;
        profilePath = "9pvgivjz.default";
      };
    };

    cli = {
      bat = enabled;
      broot = enabled;
      carapace = enabled;
      claude-code = {
        enable = true;
        scheduling.enable = true;
        selfImprove.enable = true;
      };
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
        plugins.hyprscroll.enable = true;
        extraConfig = optionalString stylixEnabled ''
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
          theme = "rose-pine-moon";
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
      audio-record = { enable = true; format = "flac"; };
      copyparty-client = enabled;
      emma = enabled;
      mail = {
        enable = true;
        protonmail-bridge.enable = true;
      };
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
