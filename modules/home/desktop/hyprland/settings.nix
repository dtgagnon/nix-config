{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  cfg = config.spirenix.desktop.hyprland;

  inherit (config.lib.stylix) colors;
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraSettings = {
      exec-once = [
        "gnome-keyring-daemon --start --components=secrets"
        "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
      ];

      input = {
        kb_layout = "us";
        accel_profile = "flat";
        follow_mouse = 1;
      };

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 3;
        "col.active_border" = mkDefault "0xff${colors.base07}";
        "col.inactive_border" = mkDefault "0xff${colors.base02}";
      };

      decoration = {
        rounding = 5;
        shadow = {
          range = 30;
          render_power = 3;
        };
        blur = {
          size = 5;
          passes = 2;
        };
      };

      animations = {
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
          "specialWorkspace, 1, 6, default, fade"
        ];
      };

      dwindle = {
        preserve_split = true;
        special_scale_factor = 1;
      };

      master = {
        new_on_top = true;
        new_status = "master";
        mfact = 0.55;
        special_scale_factor = 1;
      };

      layerrule = [
        "blur, ironbar"
        "blur, rofi"
        "blur, notification"
      ];

      misc = {
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        new_window_takes_over_fullscreen = 1;
        initial_workspace_tracking = 0;
        disable_hyprland_logo = true;
        disable_autoreload = true;
      };
    };
  };
}
