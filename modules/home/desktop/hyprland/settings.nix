{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf types;
  cfg = config.spirenix.desktop.hyprland;

  inherit (config.lib.stylix) colors;
in
{ 
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraSettings = {

      # env = [ "" ];
      # monitor = [ "" ];

      input = {
        kb_layout = "us";
        accel_profile = "flat";
        follow_mouse = 1;
        sensitivity = 0;
      };

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 3;
        active_border_color = "0xff${colors.base07}";
        inactive_border_color = "0xff${colors.base02}";
        # layout = "master";
      };

      decoration = {
        rounding = 5;
        shadow = {
          range = 30;
          render_power = 3;
        };
        blut = {
          enabled = true;
          size = 5;
          passes = 2;
        };
      };

      animations = {
        enable = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default, slidevert"
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

      binds.allow_workspace_cycles = true;

      layerrule = [
        "blur, ironbar"
        "blur, rofi"
        "blur, notifications"
      ];

      misc = {
        vrr = 2;
        disable_hyprland_logo = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        disable_autoreload = true;
        new_window_takes_over_fullscreen = 1;
        initial_workspace_tracking = 0;
      };

      exec_once =
        [
          "dbus-update-activation-environment --systemd --all"
          "systemctl --user import-environment QT_QPA_PLATFORMTHEME"
          # "${pkgs.kanshi}/bin/kanshi"
          "${pkgs.pyprland}/bin/pypr"
          "${pkgs.solaar}/bin/solaar -w hide"
          "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
        ] ++ cfg.execOnceExtras;
    };
  };
}