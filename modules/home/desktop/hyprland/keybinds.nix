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
      bind = [
        "${cfg.primaryModifier}, Return, exec, kitty"
        "${cfg.primaryModifier}, P, exec, rofi"
        "${cfg.primaryModifier}, Q, killactive,"
        "${cfg.primaryModifier}, F, fullscreen, 0"
        "${cfg.primaryModifier}, Space, togglefloating,"

        # Focus
        "${cfg.primaryModifier}, h, movefocus, l"
        "${cfg.primaryModifier}, l, movefocus, r"
        "${cfg.primaryModifier}, k, movefocus, u"
        "${cfg.primaryModifier}, j, movefocus, d"

        # Change Workspace
        "${cfg.primaryModifier}, 1, workspace, 01"
        "${cfg.primaryModifier}, 2, workspace, 02"
        "${cfg.primaryModifier}, 3, workspace, 03"
        "${cfg.primaryModifier}, 4, workspace, 04"
        "${cfg.primaryModifier}, 5, workspace, 05"
        "${cfg.primaryModifier}, 6, workspace, 06"
        "${cfg.primaryModifier}, 7, workspace, 07"
        "${cfg.primaryModifier}, 8, workspace, 08"
        "${cfg.primaryModifier}, 9, workspace, 09"
        "${cfg.primaryModifier}, 0, workspace, 10"

        # Move Workspace
        "${cfg.primaryModifier}_SHIFT, 1, movetoworkspacesilent, 01"
        "${cfg.primaryModifier}_SHIFT, 2, movetoworkspacesilent, 02"
        "${cfg.primaryModifier}_SHIFT, 3, movetoworkspacesilent, 03"
        "${cfg.primaryModifier}_SHIFT, 4, movetoworkspacesilent, 04"
        "${cfg.primaryModifier}_SHIFT, 5, movetoworkspacesilent, 05"
        "${cfg.primaryModifier}_SHIFT, 6, movetoworkspacesilent, 06"
        "${cfg.primaryModifier}_SHIFT, 7, movetoworkspacesilent, 07"
        "${cfg.primaryModifier}_SHIFT, 8, movetoworkspacesilent, 08"
        "${cfg.primaryModifier}_SHIFT, 9, movetoworkspacesilent, 09"
        "${cfg.primaryModifier}_SHIFT, 0, movetoworkspacesilent, 10"
      ];

      binde = [
        "${cfg.primaryModifier}_ALT, h, resizeactive, -20 0"
        "${cfg.primaryModifier}_ALT, l, resizeactive, 20 0"
        "${cfg.primaryModifier}_ALT, k, resizeactive, 0 -20"
        "${cfg.primaryModifier}_ALT, j, resizeactive, 0 20"
      ];
    };
  };
}
