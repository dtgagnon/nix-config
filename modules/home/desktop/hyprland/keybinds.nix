{
  lib
, pkgs
, config
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;

  resize = pkgs.writeShellScriptBin "resize" ''
    #!/usr/bin/env bash

    # Initially inspired by https://github.com/exoess

    # Getting some information about the current window
    # windowinfo=$(hyprctl activewindow) removes the newlines and won't work with grep
    hyprctl activewindow > /tmp/windowinfo
    windowinfo=/tmp/windowinfo

    # Run slurp to get position and size
    if ! slurp=$(slurp); then
    		exit
    fi

    # Parse the output
    pos_x=$(echo $slurp | cut -d " " -f 1 | cut -d , -f 1)
    pos_y=$(echo $slurp | cut -d " " -f 1 | cut -d , -f 2)
    size_x=$(echo $slurp | cut -d " " -f 2 | cut -d x -f 1)
    size_y=$(echo $slurp | cut -d " " -f 2 | cut -d x -f 2)

    # Keep the aspect ratio intact for PiP
    if grep "title: Picture-in-Picture" $windowinfo; then
    		old_size=$(grep "size: " $windowinfo | cut -d " " -f 2)
    		old_size_x=$(echo $old_size | cut -d , -f 1)
    		old_size_y=$(echo $old_size | cut -d , -f 2)

    		size_x=$(((old_size_x * size_y + old_size_y / 2) / old_size_y))
    		echo $old_size_x $old_size_y $size_x $size_y
    fi

    # Resize and move the (now) floating window
    grep "fullscreen: 1" $windowinfo && hyprctl dispatch fullscreen
    grep "floating: 0" $windowinfo && hyprctl dispatch togglefloating
    hyprctl dispatch moveactive exact $pos_x $pos_y
    hyprctl dispatch resizeactive exact $size_x $size_y
  '';
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      bind = {
        "${cfg.primaryModifier}, Return" = "exec, foot";
        "${cfg.primaryModifier}, B" = "exec, ${config.spirenix.desktop.addons.rofi.package}/bin/rofi -show drun -mode drun";
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
      bindl = { };
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