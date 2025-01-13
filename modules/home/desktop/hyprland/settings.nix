{ lib
, pkgs
, config
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;

  inherit (config.lib.stylix) colors;
  cursorSize = toString config.stylix.cursor.size;
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraConfig = ''
      general {
        col.inactive_border = 0x99${colors.base02}
      }
    '';
    spirenix.desktop.hyprland.extraSettings = {
      exec-once = [
        "gnome-keyring-daemon --start --components=secrets"
        "nm-applet"
        "hyprctl setcursor ${config.stylix.cursor.name} ${cursorSize}"
        "swww init ; sleep 1; setwall"
        "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
      ];

      monitor = cfg.monitors ++ [
        ",preferred,auto,1"
      ];

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 4;
        # "col.inactive_border" = lib.mkForce "0x99${colors.base02}";
        # resize_on_border = false;
        # allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        blur = {
          enabled = true;
          popups = true;
          size = 5;
          passes = 2;
        };
        shadow = {
          range = 30;
          render_power = 3;
        };
      };

      animations = {
        # bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        bezier = "myBezier, 0.3, 0, 0, 1";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 5, myBezier"
          "workspaces, 1, 6, default"
          "specialWorkspace, 1, 6, default, fade"
        ];
      };

      binds.allow_workspace_cycles = true;

      gestures = {
        workspace_swipe = true;
        workspace_swipe_use_r = true;
      };

      input = {
        # keyboard
        kb_layout = "us";
        repeat_delay = 200;
        repeat_rate = 100;
        # mouse
        accel_profile = "flat";
        follow_mouse = 1;
        sensitivity = 0;
        # misc
        touchpad.disable_while_typing = true;
      };

      misc = {
        new_window_takes_over_fullscreen = 2;
        initial_workspace_tracking = 0;
        disable_hyprland_logo = true;
        disable_autoreload = true;
      };

      master = {
        new_on_top = true;
        new_status = "master";
        mfact = 0.55;
        special_scale_factor = 1;
      };

      dwindle = {
        pseudotile = "yes";
        preserve_split = "yes";
        special_scale_factor = 1;
      };
    };
  };
}
