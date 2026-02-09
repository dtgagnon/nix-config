{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraWinRules = {
      windowrule = [
        # Aseprite - pixel art editor
        {
          name = "aseprite-tile";
          "match:title" = "^(Aseprite)$";
          tile = true;
        }

        # Discord - floating centered window
        {
          name = "discord";
          "match:class" = "^(discord)$";
          float = true;
          move = "50%-w/2 84";
          size = "1600 900";
        }

        # Aerc - email client floating window
        {
          name = "aerc";
          "match:title" = "^(aerc)$";
          float = true;
          center = true;
          size = "1600 1000";
          border_size = 0;
          opacity = "0.92 override 0.8 override";
        }

        # Ghostty - terminal with custom styling
        {
          name = "ghostty";
          "match:class" = "^(com.mitchellh.ghostty)$";
          float = true;
          center = true;
          size = "1200 800";
          border_size = 0;
          opacity = "0.92 override 0.8 override";
        }

        # Higher opacity for terminals running neovim (makes blur more visible, text more readable)
        {
          name = "terminal-nvim-opacity";
          "match:class" = "^(com.mitchellh.ghostty)$";
          "match:title" = ".*> (n?vim?|vi)(\\s.*)?$";
          opacity = "1.0 override 0.9 override";
        }

        # Workspace assignments
        {
          name = "thunderbird-workspace";
          "match:class" = "^(thunderbird)$";
          workspace = "6 silent";
        }
        {
          name = "looking-glass";
          "match:class" = "^(looking-glass-client)$";
          workspace = "8";
          fullscreen = true;
        }

        # Volume Control
        {
          name = "volume-control";
          "match:title" = "^(Volume Control)$";
          float = true;
          center = true;
          size = "700 450";
        }

        # Force total opacity for media viewers
        {
          name = "pip-opacity";
          "match:title" = "^(Picture in Picture)$";
          opacity = "1.0 override 1.0 override";
        }
        {
          name = "imv-opacity";
          "match:title" = "^(.*imv.*)$";
          opacity = "1.0 override 1.0 override";
        }
        {
          name = "mpv-opacity";
          "match:title" = "^(.*mpv.*)$";
          opacity = "1.0 override 1.0 override";
        }
        {
          name = "aseprite-opacity";
          "match:class" = "(Aseprite)";
          opacity = "1.0 override 1.0 override";
        }
        {
          name = "unity-opacity";
          "match:class" = "(Unity)";
          opacity = "1.0 override 1.0 override";
        }

        # Picture-in-Picture
        {
          name = "pip";
          "match:title" = "^(Picture-in-Picture)$";
          float = true;
          pin = true;
          move = "100%-h 0";
        }

        # Inhibit Idle for fullscreen videos/focused media
        {
          name = "zen-idle-inhibit";
          "match:class" = "^(zen-twilight)$";
          idle_inhibit = "fullscreen";
        }

        # Prevent windows from being maximized
        {
          name = "suppress-maximize";
          "match:class" = ".*";
          suppress_event = "maximize";
        }

        # System tray and utility windows
        {
          name = "transmission-float";
          "match:title" = "^(Transmission)$";
          float = true;
        }
        {
          name = "zen-sharing";
          "match:title" = "^(Zen Twilight — Sharing Indicator)$";
          float = true;
          move = "0 0";
        }

        # Image viewer (imv) settings - floating centered window with fixed size
        {
          name = "imv";
          "match:class" = "^(imv)$";
          float = true;
          center = true;
          size = "1200 725";
        }

        # Media player (mpv) settings - floating centered window with fixed size
        {
          name = "mpv";
          "match:class" = "^(mpv)$";
          float = true;
          pin = true;
          center = true;
          size = "1200 725";
          idle_inhibit = "focus";
        }

        # Float dialogs and notifications - using regex OR pattern for efficiency
        {
          name = "dialogs-float-class";
          "match:class" = "^(file_progress|confirm|dialog|download|notification|error|confirmreset|pavucontrol)$";
          float = true;
        }
        {
          name = "dialogs-float-title";
          "match:title" = "^(Open File|branchdialog|Confirm to replace files|File Operation Progress)$";
          float = true;
        }

        # Modal dialogs and popup windows - broader pattern matching
        {
          name = "modal-dialogs-initial-class";
          "match:class" = "^(dialog|popup|modal|utility)$";
          float = true;
        }
        {
          name = "modal-dialogs-class-pattern";
          "match:class" = ".*(dialog|Dialog|DIALOG|modal|Modal|popup|Popup).*";
          float = true;
        }
        {
          name = "modal-dialogs-title-pattern";
          "match:title" = ".*(dialog|Dialog|DIALOG|modal|Modal).*";
          float = true;
        }

        # XWaylandVideoBridge rules: These rules handle screen sharing for X11 apps (like Discord) under Wayland
        # They make the bridge window invisible, prevent animations/focus stealing, and keep it tiny (1x1)
        # This ensures smooth screen sharing without visual interference
        # NOTE: Commented out per user preference
        # {
        #   name = "xwayland-bridge-opacity";
        #   "match:class" = "^(xwaylandvideobridge)$";
        #   opacity = "0.0 override";
        # }
        # {
        #   name = "xwayland-bridge-anim";
        #   "match:class" = "^(xwaylandvideobridge)$";
        #   no_anim = true;
        # }
        # {
        #   name = "xwayland-bridge-focus";
        #   "match:class" = "^(xwaylandvideobridge)$";
        #   noinitialfocus = true;
        # }
        # {
        #   name = "xwayland-bridge-size";
        #   "match:class" = "^(xwaylandvideobridge)$";
        #   maxsize = "1 1";
        # }
        # {
        #   name = "xwayland-bridge-blur";
        #   "match:class" = "^(xwaylandvideobridge)$";
        #   noblur = true;
        # }
      ];

      layerrule = [
        {
          name = "rofi-blur";
          "match:namespace" = "rofi";
          blur = true;
        }
        {
          name = "notifications-blur";
          "match:namespace" = "notifications";
          blur = true;
          blur_popups = true;
          ignore_alpha = 0.69;
        }
      ];
    };
  };
}
