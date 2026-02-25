{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge getExe;
  cfg = config.spirenix.desktop.hyprland;
  isScrolling = cfg.layout == "scrolling";
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraKeybinds = mkMerge [
      {

        # Defaults
        "$mod" = "${cfg.hyprModifier}";
        "$terminal" = "ghostty";
        "$menu" = "rofi -show drun";
        "$lock" = ""; # defined in the lock handler's module

        bind = [
          # Open
          "$mod, Return, exec, $terminal"
          "$mod_ALT, Return, exec, $terminal"
          "$mod, E, exec, [float; center; size 1600 900] $terminal -e yazi /home/${config.spirenix.user.name}"
          "$mod, P, exec, $menu"
          "$mod_SHIFT, Z, exec, hyprshot -z -m region -t 1000 --clipboard-only"
          "$mod_SHIFT_CTRL, Z, exec, hyprshot -z -m region -t 1000 -o ~/Pictures/screenshots -f screenshot-$(date +%Y%m%d-%H%M%S).png"

          # Window Control
          "$mod, Q, killactive,"
          "$mod, F, fullscreen, 0"
          "$mod, Space, togglefloating,"
          "$mod, N, togglesplit,"

          # Focus
          (if isScrolling then "$mod, h, layoutmsg, focus l" else "$mod, h, movefocus, l")
          (if isScrolling then "$mod, l, layoutmsg, focus r" else "$mod, l, movefocus, r")
          (if isScrolling then "$mod, k, layoutmsg, focus u" else "$mod, k, movefocus, u")
          (if isScrolling then "$mod, j, layoutmsg, focus d" else "$mod, j, movefocus, d")

          # Move window
          (if isScrolling then "$mod_CTRL, h, layoutmsg, movewindowto l" else "$mod_CTRL, h, movewindow, l")
          (if isScrolling then "$mod_CTRL, l, layoutmsg, movewindowto r" else "$mod_CTRL, l, movewindow, r")
          (if isScrolling then "$mod_CTRL, k, layoutmsg, movewindowto u" else "$mod_CTRL, k, movewindow, u")
          (if isScrolling then "$mod_CTRL, j, layoutmsg, movewindowto d" else "$mod_CTRL, j, movewindow, d")

          # Change Workspace
          "$mod, 1, workspace, 01"
          "$mod, 2, workspace, 02"
          "$mod, 3, workspace, 03"
          "$mod, 4, workspace, 04"
          "$mod, 5, workspace, 05"
          "$mod, 6, workspace, 06"
          "$mod, 7, workspace, 07"
          "$mod, 8, workspace, 08"
          "$mod, 9, workspace, 09"
          "$mod, 0, workspace, 10"

          # Move Workspace
          "$mod_SHIFT, 1, movetoworkspacesilent, 01"
          "$mod_SHIFT, 2, movetoworkspacesilent, 02"
          "$mod_SHIFT, 3, movetoworkspacesilent, 03"
          "$mod_SHIFT, 4, movetoworkspacesilent, 04"
          "$mod_SHIFT, 5, movetoworkspacesilent, 05"
          "$mod_SHIFT, 6, movetoworkspacesilent, 06"
          "$mod_SHIFT, 7, movetoworkspacesilent, 07"
          "$mod_SHIFT, 8, movetoworkspacesilent, 08"
          "$mod_SHIFT, 9, movetoworkspacesilent, 09"
          "$mod_SHIFT, 0, movetoworkspacesilent, 10"

          # Special Workspaces
          # Move active window to special workspace (minimize)
          "$mod, S, movetoworkspacesilent, special:min" # General minimize to single special workspace
          "$mod, TAB, togglespecialworkspace, min" # Toggle general minimized workspace

          # Dynamic Minimize Function
          # Minimize to special workspace based on current numbered workspace
          "$mod_SHIFT, S, exec, WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id'); if [[ $WORKSPACE -ge 1 && $WORKSPACE -le 10 ]]; then hyprctl dispatch movetoworkspacesilent special:min$WORKSPACE; else hyprctl dispatch movetoworkspacesilent special:min; fi"

          # Toggle the special workspace for the current numbered workspace
          "$mod_SHIFT, TAB, exec, WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id'); if [[ $WORKSPACE -ge 1 && $WORKSPACE -le 10 ]]; then hyprctl dispatch togglespecialworkspace min$WORKSPACE; else hyprctl dispatch togglespecialworkspace min; fi"

          # General Desktop
          "$mod_SHIFT_CTRL, L, exec, $lock"

          # Submap entry points
          "$mod, A, submap, apps"
          "$mod, D, submap, display"
          "$mod, M, submap, media"
          "$mod, O, submap, obsidian"
          "$mod, W, submap, window"

          # Yell dictation
          # Shift + Space: PRESS (Toggle Start)
          (lib.optional config.spirenix.apps.yell.enable "$mod, Z, exec, sh -c 'echo \"{\\\"type\\\": \\\"ToggleRecording\\\"}\" | ${getExe pkgs.socat} - UNIX-CONNECT:$XDG_RUNTIME_DIR/yell.sock'")
          # Manual submission of dictation buffer
          (lib.optional config.spirenix.apps.yell.enable "$mod_CTRL, Z, exec, yell submit")
        ]
        ++ lib.optionals isScrolling [
          # Cycle column width through explicit_column_widths presets
          "$mod_SHIFT, h, layoutmsg, colresize -conf"
          "$mod_SHIFT, l, layoutmsg, colresize +conf"
        ];

        # Repeating (hold-able) binds
        binde = [
          # Window Size
          "$mod_ALT, h, resizeactive, -10 0"
          "$mod_ALT, l, resizeactive, 10 0"
          "$mod_ALT, k, resizeactive, 0 -10"
          "$mod_ALT, j, resizeactive, 0 10"
        ]
        ++ lib.optionals isScrolling [
          # Horizontal scroll wheel navigates columns in scrolling layout
          "$mod, mouse_left, layoutmsg, focus l"
          "$mod, mouse_right, layoutmsg, focus r"
        ];

        # Release binds
        # SUPER + Z: RELEASE (Stop if held > 250ms)
        bindr = [
          (lib.optional config.spirenix.apps.yell.enable "$mod, Z, exec, sh -c 'echo \"{\\\"type\\\": \\\"StopRecording\\\"}\" | ${getExe pkgs.socat} - UNIX-CONNECT:$XDG_RUNTIME_DIR/yell.sock'")
        ];

        # Mouse
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow 2"
        ];
      }

    ];
    wayland.windowManager.hyprland.submaps = {
      apps.settings = {
        bind = [
          ", b, exec, zen-twilight"
          ", b, submap, reset"
          ", v, exec, antigravity"
          ", v, submap, reset"
          ", d, exec, vesktop"
          ", d, submap, reset"
          ", escape, submap, reset"
        ];
      };
      display.settings = {
        bind = [
          ", i, exec, hypr-pip"
          ", i, submap, reset"
          ", escape, submap, reset"
        ];
      };
      media.settings = {
        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"
        ];
        bindl = [
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
          ", XF86AudioNext, exec, playerctl next"
        ];
        bind = [
          ", escape, submap, reset"
        ];
      };
      obsidian.settings = {
        bind = [
          ", h, exec, xdg-open 'obsidian://open?vault=dereks-head'"
          ", h, submap, reset"
          ", e, exec, xdg-open 'obsidian://open?vault=dtg-engineering'"
          ", e, submap, reset"
          ", escape, submap, reset"
        ];
      };
      window.settings = {
        bind = [
          ", escape, submap, reset"
        ]
        ++ lib.optionals isScrolling [
          # Promote window into its own column to the left
          '', h, exec, hyprctl --batch "dispatch layoutmsg promote ; dispatch layoutmsg swapcol l"''
          ", h, submap, reset"
          # Promote window into its own column to the right
          ", l, layoutmsg, promote"
          ", l, submap, reset"
        ];
        # Repeatable window appearance adjustments
        binde = [
          # Gaps
          ", code:34, exec, hyprupdategaps --inc_gaps_in ; hyprupdategaps --inc_gaps_out"
          ", code:35, exec, hyprupdategaps --dec_gaps_in ; hyprupdategaps --dec_gaps_out"
          # Border size
          "SHIFT, code:34, exec, border_size=$(hyprctl -j getoption general:border_size | jq '.int') ; hyprctl keyword general:border_size $(($border_size + 1))"
          "SHIFT, code:35, exec, border_size=$(hyprctl -j getoption general:border_size | jq '.int') ; hyprctl keyword general:border_size $(($border_size - 1))"
          # Border rounding
          "CTRL, code:34, exec, border_rounding=$(hyprctl -j getoption decoration:rounding | jq '.int') ; hyprctl keyword decoration:rounding $(($border_rounding + 1))"
          "CTRL, code:35, exec, border_rounding=$(hyprctl -j getoption decoration:rounding | jq '.int') ; hyprctl keyword decoration:rounding $(($border_rounding - 1))"
        ];
      };
    };
  };
}
