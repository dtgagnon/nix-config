{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraKeybinds = {

      # Defaults
      "$mod" = "${cfg.hyprModifier}";
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun";
      "$lock" = "hyprlock";

      bind = [
        # Open
        "$mod, Return, exec, $terminal"
        "$mod, E, exec, thunar"
        "$mod, P, exec, rofi -show drun"
        "$mod, B, exec, firefox"

        # Window Control
        "$mod, Q, killactive,"
        "$mod, F, fullscreen, 0"
        "$mod, Space, togglefloating,"
        "$mod, N, togglesplit,"

        # Focus
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

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

        # General Desktop
        "$mod_CTRL, L, exec, $lock"
      ];

      # Repeating (hold-able) binds
      binde = [
        # Window Position + Size
        "$mod_ALT, h, movewindow, l"
        "$mod_ALT, l, movewindow, r"
        "$mod_ALT, k, movewindow, u"
        "$mod_ALT, j, movewindow, d"
        "$mod_ALT_CTRL, h, resizeactive, -20 0"
        "$mod_ALT_CTRL, l, resizeactive, 20 0"
        "$mod_ALT_CTRL, k, resizeactive, 0 -20"
        "$mod_ALT_CTRL, j, resizeactive, 0 20"

        "$mod, code:34, exec, hyprupdategaps --inc_gaps_in ; hyprupdategaps --inc_gaps_out"
        "$mod, code:35, exec, hyprupdategaps --dec_gaps_in ; hyprupdategaps --dec_gaps_out"
        "$mod_SHIFT, code:34, exec, border_size=$(hyprctl -j getoption general:border_size | jq '.int') ; hyprctl keyword general:border_size $(($border_size + 1))"
        "$mod_SHIFT, code:35, exec, border_size=$(hyprctl -j getoption general:border_size | jq '.int') ; hyprctl keyword general:border_size $(($border_size - 1))"
        "$mod_CTRL_SHIFT, code:34, exec, border_rounding=$(hyprctl -j getoption decoration:rounding | jq '.int') ; hyprctl keyword decoration:rounding $(($border_rounding + 1))"
        "$mod_CTRL_SHIFT, code:35, exec, border_rounding=$(hyprctl -j getoption decoration:rounding | jq '.int') ; hyprctl keyword decoration:rounding $(($border_rounding - 1))"
      ];

      # Mouse
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow, 2"
      ];
    };
  };
}
