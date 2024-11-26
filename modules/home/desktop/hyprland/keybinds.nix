{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.desktop.hyprland;

  ################

  laptop_lid_switch = pkgs.writeShellScriptBin "laptop_lid_switch" ''
    #!/usr/bin/env bash

    if grep open /proc/acpi/button/lid/LID0/state; then
    		hyprctl keyword monitor "eDP-1, 2256x1504@60, 0x0, 1"
    else
    		if [[ `hyprctl monitors | grep "Monitor" | wc -l` != 1 ]]; then
    				hyprctl keyword monitor "eDP-1, disable"
    		else
    				systemctl suspend
    		fi
    fi
  '';

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
        # Basic Controls
        "SUPER, Return" = "exec, kitty";
        "ALT, Return" = "exec, kitty --title float_kitty";
        "SUPER_SHIFT, Return" = "exec, kitty --start-as=fullscreen -o 'font_size=16'";
        "SUPER, B" = "exec, hyprctl dispatch exec '[workspace 1 silent] floorp'";
        "SUPER, Q" = "killactive,";
        "SUPER, F" = "fullscreen, 0";
        "SUPER_SHIFT, F" = "fullscreen, 1";
        "SUPER, Space" = "togglefloating,";
        "SUPER, D" = "exec, fuzzel";
        "SUPER_SHIFT, D" = "exec, hyprctl dispatch exec '[workspace 4 silent] discord --enable-features=UseOzonePlatform --ozone-platform=wayland'";
        "SUPER_SHIFT, S" = "exec, hyprctl dispatch exec '[workspace 5 silent] SoundWireServer'";
        "SUPER, Escape" = "exec, swaylock";
        "SUPER_SHIFT, Escape" = "exec, shutdown-script";
        "SUPER, P" = "pseudo,";
        "SUPER, J" = "togglesplit,";
        "SUPER, E" = "exec, nautilus";
        "SUPER_SHIFT, B" = "exec, pkill -SIGUSR1 .waybar-wrapped";
        "SUPER, C" = "exec, hyprpicker -a";
        "SUPER, W" = "exec, wallpaper-picker";
        "SUPER_SHIFT, W" = "exec, vm-start";
        "SUPER, F1" = "exec, show-keybinds";
        "SUPER, V" = "exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy";

        # Screenshot
        "SUPER, Print" = "exec, grimblast --notify --cursor --freeze save area ~/Pictures/$(date +'%Y-%m-%d-At-%Ih%Mm%Ss').png";
        ",Print" = "exec, grimblast --notify --cursor --freeze copy area";

        # Focus
        "SUPER, h" = "movefocus, l";
        "SUPER, l" = "movefocus, r";
        "SUPER, k" = "movefocus, u";
        "SUPER, j" = "movefocus, d";
        "SUPER, left" = "movefocus, l";
        "SUPER, right" = "movefocus, r";
        "SUPER, up" = "movefocus, u";
        "SUPER, down" = "movefocus, d";
        "SUPERCONTROL, h" = "focusmonitor, l";
        "SUPERCONTROL, l" = "focusmonitor, r";
        "SUPERCONTROL, k" = "focusmonitor, u";
        "SUPERCONTROL, j" = "focusmonitor, d";

        # Window Control
        "SUPER_SHIFT, left" = "movewindow, l";
        "SUPER_SHIFT, right" = "movewindow, r";
        "SUPER_SHIFT, up" = "movewindow, u";
        "SUPER_SHIFT, down" = "movewindow, d";
        "SUPER_CTRL, left" = "resizeactive, -80 0";
        "SUPER_CTRL, right" = "resizeactive, 80 0";
        "SUPER_CTRL, up" = "resizeactive, 0 -80";
        "SUPER_CTRL, down" = "resizeactive, 0 80";
        "SUPER_ALT, left" = "moveactive, -80 0";
        "SUPER_ALT, right" = "moveactive, 80 0";
        "SUPER_ALT, up" = "moveactive, 0 -80";
        "SUPER_ALT, down" = "moveactive, 0 80";
        "SUPER_CTRL, c" = "movetoworkspace, empty";

        # Mouse Scroll Workspace Switch
        "SUPER, mouse_down" = "workspace, e-1";
        "SUPER, mouse_up" = "workspace, e+1";

        # Lock Screen
        ",XF86Launch5" = "exec, hyprlock";
        ",XF86Launch4" = "exec, hyprlock";
        "SUPER,backspace" = "exec, hyprlock";
        "CTRL_SUPER,backspace" = "exec, wlogout --column-spacing 50 --row-spacing 50";

        # Change Workspace
        "SUPER,1" = "workspace,01";
        "SUPER,2" = "workspace,02";
        "SUPER,3" = "workspace,03";
        "SUPER,4" = "workspace,04";
        "SUPER,5" = "workspace,05";
        "SUPER,6" = "workspace,06";
        "SUPER,7" = "workspace,07";
        "SUPER,8" = "workspace,08";
        "SUPER,9" = "workspace,09";
        "SUPER,0" = "workspace,10";

        # Move Workspace
        "SUPERSHIFT,1" = "movetoworkspacesilent,01";
        "SUPERSHIFT,2" = "movetoworkspacesilent,02";
        "SUPERSHIFT,3" = "movetoworkspacesilent,03";
        "SUPERSHIFT,4" = "movetoworkspacesilent,04";
        "SUPERSHIFT,5" = "movetoworkspacesilent,05";
        "SUPERSHIFT,6" = "movetoworkspacesilent,06";
        "SUPERSHIFT,7" = "movetoworkspacesilent,07";
        "SUPERSHIFT,8" = "movetoworkspacesilent,08";
        "SUPERSHIFT,9" = "movetoworkspacesilent,09";
        "SUPERSHIFT,0" = "movetoworkspacesilent,10";
        "SUPERALT,h" = "movecurrentworkspacetomonitor,l";
        "SUPERALT,l" = "movecurrentworkspacetomonitor,r";
        "SUPERALT,k" = "movecurrentworkspacetomonitor,u";
        "SUPERALT,j" = "movecurrentworkspacetomonitor,d";
        "ALTCTRL,L" = "movewindow,r";
        "ALTCTRL,H" = "movewindow,l";
        "ALTCTRL,K" = "movewindow,u";
        "ALTCTRL,J" = "movewindow,d";

        # Swap windows
        "SUPERSHIFT,h" = "swapwindow,l";
        "SUPERSHIFT,l" = "swapwindow,r";
        "SUPERSHIFT,k" = "swapwindow,u";
        "SUPERSHIFT,j" = "swapwindow,d";

        # Scratch Pad
        "SUPER,u" = "togglespecialworkspace";
        "SUPERSHIFT,u" = "movetoworkspace,special";
      };
      bindi = {
        ",XF86MonBrightnessUp" = "exec, brightnessctl set 5%+";
        ",XF86MonBrightnessDown" = "exec, brightnessctl set 5%-";
        "SUPER,XF86MonBrightnessUp" = "exec, brightnessctl set 100%+";
        "SUPER,XF86MonBrightnessDown" = "exec, brightnessctl set 100%-";
        ",XF86AudioRaiseVolume" = "exec, pamixer -i 2";
        ",XF86AudioLowerVolume" = "exec, pamixer -d 2";
        ",XF86AudioMute" = "exec, pamixer -t";
        ",XF86AudioPlay" = "exec, playerctl play-pause";
        ",XF86AudioNext" = "exec, playerctl next";
        ",XF86AudioPrev" = "exec, playerctl previous";
        ",XF86AudioStop" = "exec, playerctl stop";
      };
      bindl = {
        ",switch:Lid Switch" = "exec, ${laptop_lid_switch}/bin/laptop_lid_switch";
      };
      binde = {
        "SUPERALT, h" = "resizeactive, -20 0";
        "SUPERALT, l" = "resizeactive, 20 0";
        "SUPERALT, k" = "resizeactive, 0 -20";
        "SUPERALT, j" = "resizeactive, 0 20";
      };
      bindm = {
        "SUPER, mouse:272" = "movewindow";
        "SUPER, mouse:273" = "resizewindow";
      };
    };
  };
}