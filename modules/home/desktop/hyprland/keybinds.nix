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
      "$mod" = "${cfg.primaryModifier}"
      bind = [
        "$mod, Return" = "exec, wezterm"
        "$mod, B" = "exec, ${config.spirenix.desktop.addons.rofi.package}/bin/rofi -show drun -mode drun"
        "$mod, Q" = "killactive,"
        "$mod, F" = "Fullscreen,0"
        "$mod, R" = "exec, ${resize}/bin/resize"
        "$mod, Space" = "togglefloating,"
        "$mod, V" = "exec, ${pkgs.pyprland}/bin/pypr toggle pwvucontrol"
        "$mod_SHIFT, T" = "exec, ${pkgs.pyprland}/bin/pypr toggle term"

        # Lock Screen
        ",XF86Launch5" = "exec,${pkgs.hyprlock}/bin/hyprlock"
        ",XF86Launch4" = "exec,${pkgs.hyprlock}/bin/hyprlock"
        "$mod,backspace" = "exec,${pkgs.hyprlock}/bin/hyprlock"
        "CTRL_$mod,backspace" = "exec,wlogout --column-spacing 50 --row-spacing 50"

        # Screenshot
        ",Print" = "exec,grimblast --notify copysave area"
        "SHIFT, Print" = "exec,grimblast --notify copy active"
        "CONTROL,Print" = "exec,grimblast --notify copy screen"
        "$mod,Print" = "exec,grimblast --notify copy window"
        "ALT,Print" = "exec,grimblast --notify copy area"
        "$mod,bracketleft" = "exec,grimblast --notify --cursor copysave area ~/Pictures/$(date \" + %Y-%m-%d \"T\"%H:%M:%S_no_watermark \").png"
        "$mod,bracketright" = "exec, grimblast --notify --cursor copy area"

        # Focus
        "$mod,h" = "movefocus,l"
        "$mod,l" = "movefocus,r"
        "$mod,k" = "movefocus,u"
        "$mod,j" = "movefocus,d"
        "$modCONTROL,h" = "focusmonitor,l"
        "$modCONTROL,l" = "focusmonitor,r"
        "$modCONTROL,k" = "focusmonitor,u"
        "$modCONTROL,j" = "focusmonitor,d"

        # Change Workspace
        "$mod,1" = "workspace,01"
        "$mod,2" = "workspace,02"
        "$mod,3" = "workspace,03"
        "$mod,4" = "workspace,04"
        "$mod,5" = "workspace,05"
        "$mod,6" = "workspace,06"
        "$mod,7" = "workspace,07"
        "$mod,8" = "workspace,08"
        "$mod,9" = "workspace,09"
        "$mod,0" = "workspace,10"

        # Move Workspace
        "$modSHIFT,1" = "movetoworkspacesilent,01"
        "$modSHIFT,2" = "movetoworkspacesilent,02"
        "$modSHIFT,3" = "movetoworkspacesilent,03"
        "$modSHIFT,4" = "movetoworkspacesilent,04"
        "$modSHIFT,5" = "movetoworkspacesilent,05"
        "$modSHIFT,6" = "movetoworkspacesilent,06"
        "$modSHIFT,7" = "movetoworkspacesilent,07"
        "$modSHIFT,8" = "movetoworkspacesilent,08"
        "$modSHIFT,9" = "movetoworkspacesilent,09"
        "$modSHIFT,0" = "movetoworkspacesilent,10"
        "$modALT,h" = "movecurrentworkspacetomonitor,l"
        "$modALT,l" = "movecurrentworkspacetomonitor,r"
        "$modALT,k" = "movecurrentworkspacetomonitor,u"
        "$modALT,j" = "movecurrentworkspacetomonitor,d"
        "ALTCTRL,L" = "movewindow,r"
        "ALTCTRL,H" = "movewindow,l"
        "ALTCTRL,K" = "movewindow,u"
        "ALTCTRL,J" = "movewindow,d"

        # Swap windows
        "$modSHIFT,h" = "swapwindow,l"
        "$modSHIFT,l" = "swapwindow,r"
        "$modSHIFT,k" = "swapwindow,u"
        "$modSHIFT,j" = "swapwindow,d"

        # Scratch Pad
        "$mod,u" = "togglespecialworkspace"
        "$modSHIFT,u" = "movetoworkspace,special"
      ]
      bindi = [
        ",XF86MonBrightnessUp" = "exec, ${pkgs.brightnessctl}/bin/brightnessctl +5%"
        ",XF86MonBrightnessDown" = "exec, ${pkgs.brightnessctl}/bin/brightnessctl -5% "
        ",XF86AudioRaiseVolume" = "exec, ${pkgs.pamixer}/bin/pamixer -i 5"
        ",XF86AudioLowerVolume" = "exec, ${pkgs.pamixer}/bin/pamixer -d 5"
        ",XF86AudioMute" = "exec, ${pkgs.pamixer}/bin/pamixer --toggle-mute"
        ",XF86AudioMicMute" = "exec, ${pkgs.pamixer}/bin/pamixer --default-source --toggle-mute"
        ",XF86AudioNext" = "exec,playerctl next"
        ",XF86AudioPrev" = "exec,playerctl previous"
        ",XF86AudioPlay" = "exec,playerctl play-pause"
        ",XF86AudioStop" = "exec,playerctl stop"
      ]
      bindl = [ ]
      binde = [
        "$modALT, h" = "resizeactive, -20 0"
        "$modALT, l" = "resizeactive, 20 0"
        "$modALT, k" = "resizeactive, 0 -20"
        "$modALT, j" = "resizeactive, 0 20"
      ]
    };
  };
}