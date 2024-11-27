{
  lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.hyprland;
in {
  options.${namespace}.desktop.hyprland = {
    primaryModifier = mkOpt types.string "SUPER" "The primary modifier key.";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.keyBinds = {
      bind = {
        "${cfg.primaryModifier}, Return" = "exec, foot";
        "${cfg.primaryModifier}, B" = "exec, ${config.desktops.addons.rofi.package}/bin/rofi -show drun -mode drun";
        "${cfg.primaryModifier}, Q" = "killactive,";
        "${cfg.primaryModifier}, F" = "Fullscreen,0";
        "${cfg.primaryModifier}, R" = "exec, ${resize}/bin/resize";
        "${cfg.primaryModifier}, Space" = "togglefloating,";
        "${cfg.primaryModifier}, V" = "exec, ${pkgs.pyprland}/bin/pypr toggle pwvucontrol";
        "${cfg.primaryModifier}_SHIFT, T" = "exec, ${pkgs.pyprland}/bin/pypr toggle term";

        # Lock Screen
        ",XF86Launch5" = "exec,${pkgs.hyprlock}/bin/hyprlock";
        ",XF86Launch4" = "exec,${pkgs.hyprlock}/bin/hyprlock";
        "${cfg.primaryModifier},backspace" = "exec,${pkgs.hyprlock}/bin/hyprlock";
        "CTRL_${cfg.primaryModifier},backspace" = "exec,wlogout --column-spacing 50 --row-spacing 50";

        # Screenshot
        ",Print" = "exec,grimblast --notify copysave area";
        "SHIFT, Print" = "exec,grimblast --notify copy active";
        "CONTROL,Print" = "exec,grimblast --notify copy screen";
        "${cfg.primaryModifier},Print" = "exec,grimblast --notify copy window";
        "ALT,Print" = "exec,grimblast --notify copy area";
        "${cfg.primaryModifier},bracketleft" = "exec,grimblast --notify --cursor copysave area ~/Pictures/$(date \" + %Y-%m-%d \"T\"%H:%M:%S_no_watermark \").png";
        "${cfg.primaryModifier},bracketright" = "exec, grimblast --notify --cursor copy area";

        # Focus
        "${cfg.primaryModifier},h" = "movefocus,l";
        "${cfg.primaryModifier},l" = "movefocus,r";
        "${cfg.primaryModifier},k" = "movefocus,u";
        "${cfg.primaryModifier},j" = "movefocus,d";
        "${cfg.primaryModifier}CONTROL,h" = "focusmonitor,l";
        "${cfg.primaryModifier}CONTROL,l" = "focusmonitor,r";
        "${cfg.primaryModifier}CONTROL,k" = "focusmonitor,u";
        "${cfg.primaryModifier}CONTROL,j" = "focusmonitor,d";

        # Change Workspace
        "${cfg.primaryModifier},1" = "workspace,01";
        "${cfg.primaryModifier},2" = "workspace,02";
        "${cfg.primaryModifier},3" = "workspace,03";
        "${cfg.primaryModifier},4" = "workspace,04";
        "${cfg.primaryModifier},5" = "workspace,05";
        "${cfg.primaryModifier},6" = "workspace,06";
        "${cfg.primaryModifier},7" = "workspace,07";
        "${cfg.primaryModifier},8" = "workspace,08";
        "${cfg.primaryModifier},9" = "workspace,09";
        "${cfg.primaryModifier},0" = "workspace,10";

        # Move Workspace
        "${cfg.primaryModifier}SHIFT,1" = "movetoworkspacesilent,01";
        "${cfg.primaryModifier}SHIFT,2" = "movetoworkspacesilent,02";
        "${cfg.primaryModifier}SHIFT,3" = "movetoworkspacesilent,03";
        "${cfg.primaryModifier}SHIFT,4" = "movetoworkspacesilent,04";
        "${cfg.primaryModifier}SHIFT,5" = "movetoworkspacesilent,05";
        "${cfg.primaryModifier}SHIFT,6" = "movetoworkspacesilent,06";
        "${cfg.primaryModifier}SHIFT,7" = "movetoworkspacesilent,07";
        "${cfg.primaryModifier}SHIFT,8" = "movetoworkspacesilent,08";
        "${cfg.primaryModifier}SHIFT,9" = "movetoworkspacesilent,09";
        "${cfg.primaryModifier}SHIFT,0" = "movetoworkspacesilent,10";
        "${cfg.primaryModifier}ALT,h" = "movecurrentworkspacetomonitor,l";
        "${cfg.primaryModifier}ALT,l" = "movecurrentworkspacetomonitor,r";
        "${cfg.primaryModifier}ALT,k" = "movecurrentworkspacetomonitor,u";
        "${cfg.primaryModifier}ALT,j" = "movecurrentworkspacetomonitor,d";
        "ALTCTRL,L" = "movewindow,r";
        "ALTCTRL,H" = "movewindow,l";
        "ALTCTRL,K" = "movewindow,u";
        "ALTCTRL,J" = "movewindow,d";

        # Swap windows
        "${cfg.primaryModifier}SHIFT,h" = "swapwindow,l";
        "${cfg.primaryModifier}SHIFT,l" = "swapwindow,r";
        "${cfg.primaryModifier}SHIFT,k" = "swapwindow,u";
        "${cfg.primaryModifier}SHIFT,j" = "swapwindow,d";

        # Scratch Pad
        "${cfg.primaryModifier},u" = "togglespecialworkspace";
        "${cfg.primaryModifier}SHIFT,u" = "movetoworkspace,special";
      };
      bindi = {
        ",XF86MonBrightnessUp" = "exec, ${pkgs.brightnessctl}/bin/brightnessctl +5%";
        ",XF86MonBrightnessDown" = "exec, ${pkgs.brightnessctl}/bin/brightnessctl -5% ";
        ",XF86AudioRaiseVolume" = "exec, ${pkgs.pamixer}/bin/pamixer -i 5";
        ",XF86AudioLowerVolume" = "exec, ${pkgs.pamixer}/bin/pamixer -d 5";
        ",XF86AudioMute" = "exec, ${pkgs.pamixer}/bin/pamixer --toggle-mute";
        ",XF86AudioMicMute" = "exec, ${pkgs.pamixer}/bin/pamixer --default-source --toggle-mute";
        ",XF86AudioNext" = "exec,playerctl next";
        ",XF86AudioPrev" = "exec,playerctl previous";
        ",XF86AudioPlay" = "exec,playerctl play-pause";
        ",XF86AudioStop" = "exec,playerctl stop";
      };
      bindl = {
        ",switch:Lid Switch" = "exec, ${laptop_lid_switch}/bin/laptop_lid_switch";
      };
      binde = {
        "${cfg.primaryModifier}ALT, h" = "resizeactive, -20 0";
        "${cfg.primaryModifier}ALT, l" = "resizeactive, 20 0";
        "${cfg.primaryModifier}ALT, k" = "resizeactive, 0 -20";
        "${cfg.primaryModifier}ALT, j" = "resizeactive, 0 20";
      };
      bindm = {
        "${cfg.primaryModifier}, mouse:272" = "movewindow";
        "${cfg.primaryModifier}, mouse:273" = "resizewindow";
      };
    };
  };
}