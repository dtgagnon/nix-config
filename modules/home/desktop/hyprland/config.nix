{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
with lib; let
  cfg = config.${namespace}.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      general = {
        layout = "dwindle";
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        "col.active_border" = mkForce "rgb(cba6f7) rgb(94e2d5) 45deg";
        "col.inactive_border" = mkForce "0x00000000";
        border_part_of_window = false;
        no_border_on_floating = false;
      };

      misc = {
        disable_autoreload = true;
        disable_hyprland_logo = true;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = false;
        enable_swallow = true;
        focus_on_activate = true;
      };

      dwindle = {
        no_gaps_when_only = true;
        force_split = 0;
        special_scale_factor = 1.0;
        split_width_multiplier = 1.0;
        use_active_for_splits = true;
        pseudotile = "yes";
        preserve_split = "yes";
      };

      master = {
        new_status = "master";
        special_scale_factor = 1;
        no_gaps_when_only = false;
      };

      decoration = {
        rounding = 0;
        blur = {
          enabled = true;
          size = 1;
          passes = 1;
          brightness = 1;
          contrast = 1.400;
          ignore_opacity = true;
          noise = 0;
          new_optimizations = true;
          xray = true;
        };

        drop_shadow = true;
        shadow_ignore_window = true;
        shadow_offset = "0 2";
        shadow_range = 20;
        shadow_render_power = 3;
        "col.shadow" = "rgba(00000055)";
      };

      animations = {
        enabled = true;

        bezier = [
          "fluent_decel, 0, 0.2, 0.4, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "easeinoutsine, 0.37, 0, 0.63, 1"
        ];

        animation = [
          # Windows
          "windowsIn, 1, 3, easeOutCubic, popin 30%" # window open
          "windowsOut, 1, 3, fluent_decel, popin 70%" # window close
          "windowsMove, 1, 2, easeinoutsine, slide" # everything in between, moving, dragging, resizing

          # Fade
          "fadeIn, 1, 3, easeOutCubic" # fade in (open) -> layers and windows
          "fadeOut, 1, 2, easeOutCubic" # fade out (close) -> layers and windows
          "fadeSwitch, 0, 1, easeOutCirc" # fade on changing activewindow and its opacity
          "fadeShadow, 1, 10, easeOutCirc" # fade on changing activewindow for shadows
          "fadeDim, 1, 4, fluent_decel" # the easing of the dimming of inactive windows
          "border, 1, 2.7, easeOutCirc" # for animating the border's color switch speed
          "borderangle, 1, 30, fluent_decel, once" # for animating the border's gradient angle
          "workspaces, 1, 4, easeOutCubic, fade" # styles: slide, slidevert, fade, slidefade, slidefadevert
        ];
      };

      exec-once = [
        "systemctl --user import-environment &"
        "hash dbus-update-activation-environment 2>/dev/null &"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &"
        "nm-applet &"
        "wl-clip-persist --clipboard both"
        "swaybg -m fill -i $(find ~/Pictures/wallpapers/ -maxdepth 1 -type f) &"
        "hyprctl setcursor Nordzy-cursors 22 &"
        "poweralertd &"
        "waybar &"
        "swaync &"
        "wl-paste --watch cliphist store &"
        "hyprlock"
      ];

      input = {
        kb_layout = "us";
        kb_options = "grp:alt_caps_toggle";
        numlock_by_default = true;
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
        };
      };

      monitor = ",preferred,auto,auto";

      xwayland.force_zero_scaling = true;
    };
  };
}