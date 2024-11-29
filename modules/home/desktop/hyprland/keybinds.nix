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
    spirenix.desktop.hyprland.extraKeybinds = {
      bind = [
        "${primaryModifier}, Return, exec wezterm"
        "${primaryModifier}, B, exec ${config.spirenix.desktop.addons.rofi.package}/bin/rofi -show drun -mode drun"
        "${primaryModifier}, Q, killactive"
        "${primaryModifier}, F, fullscreen 0"
        "${primaryModifier}, R, exec ${resize}/bin/resize"
        "${primaryModifier}, Space, togglefloating"
        "${primaryModifier}, V, exec ${pkgs.pyprland}/bin/pypr toggle pwvucontrol"
        "${primaryModifier}_SHIFT, T, exec ${pkgs.pyprland}/bin/pypr toggle term"

        # Lock Screen
        ", XF86Launch5, exec ${pkgs.hyprlock}/bin/hyprlock"
        ", XF86Launch4, exec ${pkgs.hyprlock}/bin/hyprlock"
        "${primaryModifier}, backspace, exec ${pkgs.hyprlock}/bin/hyprlock"
        "CTRL_${primaryModifier}, backspace, exec wlogout --column-spacing 50 --row-spacing 50"

        # Screenshot
        ", Print, exec grimblast --notify copysave area"
        "SHIFT, Print, exec grimblast --notify copy active"
        "CONTROL, Print, exec grimblast --notify copy screen"
        "${primaryModifier}, Print, exec grimblast --notify copy window"
        "ALT, Print, exec grimblast --notify copy area"
        "${primaryModifier}, bracketleft, exec grimblast --notify --cursor copysave area ~/Pictures/$(date \" + %Y-%m-%d \"T\"%H:%M:%S_no_watermark \").png"
        "${primaryModifier}, bracketright, exec grimblast --notify --cursor copy area"

        # Focus
        "${primaryModifier}, h, movefocus l"
        "${primaryModifier}, l, movefocus r"
        "${primaryModifier}, k, movefocus u"
        "${primaryModifier}, j, movefocus d"
        "${primaryModifier}_CONTROL, h, focusmonitor l"
        "${primaryModifier}_CONTROL, l, focusmonitor r"
        "${primaryModifier}_CONTROL, k, focusmonitor u"
        "${primaryModifier}_CONTROL, j, focusmonitor d"

        # Change Workspace
        "${primaryModifier}, 1, workspace 01"
        "${primaryModifier}, 2, workspace 02"
        "${primaryModifier}, 3, workspace 03"
        "${primaryModifier}, 4, workspace 04"
        "${primaryModifier}, 5, workspace 05"
        "${primaryModifier}, 6, workspace 06"
        "${primaryModifier}, 7, workspace 07"
        "${primaryModifier}, 8, workspace 08"
        "${primaryModifier}, 9, workspace 09"
        "${primaryModifier}, 0, workspace 10"

        # Move Workspace
        "${primaryModifier}_SHIFT, 1, movetoworkspacesilent 01"
        "${primaryModifier}_SHIFT, 2, movetoworkspacesilent 02"
        "${primaryModifier}_SHIFT, 3, movetoworkspacesilent 03"
        "${primaryModifier}_SHIFT, 4, movetoworkspacesilent 04"
        "${primaryModifier}_SHIFT, 5, movetoworkspacesilent 05"
        "${primaryModifier}_SHIFT, 6, movetoworkspacesilent 06"
        "${primaryModifier}_SHIFT, 7, movetoworkspacesilent 07"
        "${primaryModifier}_SHIFT, 8, movetoworkspacesilent 08"
        "${primaryModifier}_SHIFT, 9, movetoworkspacesilent 09"
        "${primaryModifier}_SHIFT, 0, movetoworkspacesilent 10"
        "${primaryModifier}_ALT, h, movecurrentworkspacetomonitor l"
        "${primaryModifier}_ALT, l, movecurrentworkspacetomonitor r"
        "${primaryModifier}_ALT, k, movecurrentworkspacetomonitor u"
        "${primaryModifier}_ALT, j, movecurrentworkspacetomonitor d"
        "ALT_CTRL, L, movewindow r"
        "ALT_CTRL, H, movewindow l"
        "ALT_CTRL, K, movewindow u"
        "ALT_CTRL, J, movewindow d"

        # Swap windows
        "${primaryModifier}SHIFT, h, swapwindow l"
        "${primaryModifier}SHIFT, l, swapwindow r"
        "${primaryModifier}SHIFT, k, swapwindow u"
        "${primaryModifier}SHIFT, j, swapwindow d"

        # Scratch Pad
        "${primaryModifier}, u, togglespecialworkspace"
        "${primaryModifier}_SHIFT, u, movetoworkspace special"
      ];
      bindi = [
        ", XF86MonBrightnessUp, exec ${pkgs.brightnessctl}/bin/brightnessctl +5%"
        ", XF86MonBrightnessDown, exec ${pkgs.brightnessctl}/bin/brightnessctl -5%"
        ", XF86AudioRaiseVolume, exec ${pkgs.pamixer}/bin/pamixer -i 5"
        ", XF86AudioLowerVolume, exec ${pkgs.pamixer}/bin/pamixer -d 5"
        ", XF86AudioMute, exec ${pkgs.pamixer}/bin/pamixer --toggle-mute"
        ", XF86AudioMicMute, exec ${pkgs.pamixer}/bin/pamixer --default-source --toggle-mute"
        ", XF86AudioNext, exec playerctl next"
        ", XF86AudioPrev, exec playerctl previous"
        ", XF86AudioPlay, exec playerctl play-pause"
        ", XF86AudioStop, exec playerctl stop"
      ];
      bindl = [ ];
      binde = [
        "${primaryModifier}_ALT, h, resizeactive -20 0"
        "${primaryModifier}_ALT, l, resizeactive 20 0"
        "${primaryModifier}_ALT, k, resizeactive 0 -20"
        "${primaryModifier}_ALT, j, resizeactive 0 20"
      ];
    };
  };
}
