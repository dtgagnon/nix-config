{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (config.lib.stylix) colors;
  cfg = config.${namespace}.desktop.addons.waybar;

  core = config.spirenix.desktop.styling.core;
  spanWrapIcon = icon: ''<span face="${core.fonts.monospace.name}" size="20pt">${icon}</span>'';
  spanWrapText = text: ''<span face="${core.fonts.sansSerif.name}" size="12pt" rise="5pt">${text}</span>'';
in
{
  config = mkIf (cfg.presetLayout == "top-isolated-islands-centeredWorkspaces") {
    spirenix.desktop.addons.waybar.settings = [
      {
        layer = "top";
        position = "top";
        margin = "0 0 0 0";
        modules-left = [
          "group/utilities"
          "group/hardware"
          "group/audioControl"
        ];
        modules-center = [
          "hyprland/workspaces#odds"
          "custom/startmenu"
          "hyprland/workspaces#evens"
        ];
        modules-right = [
          "custom/notification"
          "tray"
          "clock#calendar"
          "clock#clock"
        ];

        # Custom grouping of modules
        "group/utilities" = {
          orientation = "inherit";
          modules = [
            "custom/exit"
          ];
        };

        "group/hardware" = {
          orientation = "inherit";
          modules = [
            "battery"
            "backlight"
            "memory"
            "cpu"
            "temperature"
          ];
        };

        "group/audioControl" = {
          orientation = "inherit";
          modules = [
            "pulseaudio"
            "custom/music"
          ];
        };

        ##### 󰲌   󰎞   󰺵  󰝦    #####
        "hyprland/workspaces#odds" = {
          persistent-workspaces = {
            "1" = spanWrapIcon "";
          };
          format = "{icon}";
          format-icons = {
            "1" = spanWrapIcon "";
            "3" = spanWrapIcon "";
            "5" = spanWrapIcon "󰎞";
            "default" = spanWrapIcon "󰝦";
            "urgent" = spanWrapIcon "";
          };
          on-click = "activate";
          ignore-workspaces = [
            "2"
            "4"
            "6"
            "8"
            "10"
          ];
          "sort-by" = "number";
          "sort-desc" = true;
        };

        "hyprland/workspaces#evens" = {
          persistent-workspaces = {
            "2" = spanWrapIcon "";
          };
          format = "{icon}";
          format-icons = {
            "2" = spanWrapIcon "";
            "4" = spanWrapIcon "";
            "6" = spanWrapIcon "";
            "default" = spanWrapIcon "󰝦";
            "urgent" = spanWrapIcon "";
          };
          on-click = "activate";
          ignore-workspaces = [
            "1"
            "3"
            "5"
            "7"
            "9"
          ];
          "sort-by" = "number";
        };

        ### v--- Individual module configuration ---v ###
        "clock#clock" = {
          format = "{:%I:%M<small>%p</small>}";
          interval = 15;
          tooltip = false;
        };

        "clock#calendar" = {
          format = "{:%a, %b. %d}";
          interval = 1;
          tooltip-format = "<tt>{calendar}</tt>";
          calendar = {
            mode = "month";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            "on-click-right" = "mode";
            format = {
              months = "<span color='#${colors.base05}'><b>{}</b></span>";
              days = "<span color='#${colors.base06}'>{}</span>";
              weeks = "<span color='#${colors.base07}'>w{}</span>";
              weekdays = "<span color='#${colors.base08}'>{}</span>";
              today = "<span color='#${colors.base09}'><b><u>{}</u></b></span>";
            };
          };
        };

        temperature = {
          "hwmon-path" = "/sys/class/hwmon/hwmon5/temp1_input";
          interval = 5;
          format = spanWrapText "{temperatureC}°";
          tooltip = false;
          critical-threshold = 80;
          format-critical = spanWrapText "{temperatureC}° " + spanWrapIcon "<span color='#FF2800'></span>";
        };

        cpu = {
          interval = 5;
          format = spanWrapText "{usage}<small>%</small> " + spanWrapIcon "";
          tooltip = true;
        };

        memory = {
          interval = 5;
          format = spanWrapText "{used}<small>G</small> " + spanWrapIcon "";
          tooltip = false;
        };

        backlight = {
          format = spanWrapIcon "" + " {percent}%;";
        };

        pulseaudio = {
          scroll-step = 2;
          format = spanWrapText "{volume}<small>%</small> " + "{icon}";
          format-bluetooth = "{volume}<small>%</small> {icon}";
          format-bluetooth-muted = spanWrapIcon "󰝟";
          format-muted = spanWrapIcon "󰝟";
          format-source = spanWrapIcon "";
          format-source-muted = spanWrapIcon "";
          format-icons = {
            headphone = spanWrapIcon "";
            hands-free = spanWrapIcon "󰋎";
            headset = spanWrapIcon "󰋎";
            phone = spanWrapIcon "";
            portable = spanWrapIcon "";
            car = spanWrapIcon "";
            default = [
              (spanWrapIcon "")
              (spanWrapIcon "")
              (spanWrapIcon "")
            ];
          };
          on-click = "sleep 0.1 && pavucontrol";
        };

        tray = {
          icon-size = 20;
          spacing = 8;
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = spanWrapIcon "󰂄" + " {capacity}%";
          format-plugged = spanWrapIcon "󱘖" + " {capacity}%";
          format-icons = [
            (spanWrapIcon "󰁺")
            (spanWrapIcon "󰁻")
            (spanWrapIcon "󰁼")
            (spanWrapIcon "󰁾")
            (spanWrapIcon "󰁿")
            (spanWrapIcon "󰂀")
            (spanWrapIcon "󰂁")
            (spanWrapIcon "󰂂")
          ];
          on-click = "";
          tooltip = false;
        };

        #====================CUSTOM MODULES====================
        "custom/exit" = {
          tooltip = false;
          format = spanWrapIcon "";
          on-click = "sleep 0.1 && wlogout";
        };

        "custom/hyprbindings" = {
          tooltip = false;
          format = spanWrapIcon "󱕴";
          on-click = "sleep 0.1 && hyprctl binds";
        };

        "custom/music" = {
          format = "𝄞 {}";
          escape = true;
          interval = 2;
          tooltip = false;
          exec = "playerctl metadata --format '{{ title }} - {{ artist }}'";
          on-click = "playerctl play-pause";
          max-length = 30;
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon}";
          "format-icons" = {
            "notification" = spanWrapIcon "<span foreground='red'><sup>󱅫</sup></span>";
            "none" = spanWrapIcon "";
            "dnd-notification" = spanWrapIcon "<span foreground='red'><sup></sup></span>";
            "dnd-none" = spanWrapIcon "󰂛";
            "inhibited-notification" = spanWrapIcon "<span foreground='red'><sup></sup></span>";
            "inhibited-none" = spanWrapIcon "";
            "dnd-inhibited-notification" = spanWrapIcon "<span foreground='red'><sup></sup></span>";
            "dnd-inhibited-none" = spanWrapIcon "";
          };
          return-type = "json";
          exec-if = "which makoctl";
          exec = ''
            makoctl list | jq --unbuffered --compact-output '
            .data[0] as $notifications
            | if ($notifications|length) > 0 then
            { "alt": "notification", "tooltip": ($notifications[0].summary + ":\n" + $notifications[0].body) }
            else
            { "alt": "none", "tooltip": "" }
            end
            '
          '';
          on-click = "makoctl invoke";
          on-click-right = "sleep 0.1 && makoctl dismiss";
          escape = false;

          interval = 5;
        };

        "custom/startmenu" = {
          tooltip = false;
          format = "<span size='36pt'><tt></tt></span>";
          on-click = "sleep 0.1 && if pgrep -x \"rofi\" > /dev/null; then killall rofi; else rofi -show drun; fi";
        };
      }
    ];
  };
}
