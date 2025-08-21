{ lib
, config
, namespace
, osConfig
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) prependUWSM;
  cfg = config.spirenix.desktop.hyprland;

  cursorSize = toString config.stylix.cursor.size;
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraSettings = {
      exec-once =
        let
          execCmds = ([
            "gnome-keyring-daemon --start --components=secrets"
            # "hyprctl setcursor ${config.stylix.cursor.name} ${cursorSize}"
            "nm-applet"
            "swww init ; sleep 1; setwall"
            "playerctld daemon"
          ] ++ cfg.extraExec);
        in
        if osConfig.programs.hyprland.withUWSM then
          map (c: "uwsm app -- ${c}") execCmds
        else execCmds;


      monitor = cfg.monitors ++ [
        "Virtual-1,3440x1440,0x0,1"
        # ",preferred,auto,1"
      ];

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 3;
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        blur = {
          enabled = true;
          special = true;
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
        # kb_options = "caps:swapescape";
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
