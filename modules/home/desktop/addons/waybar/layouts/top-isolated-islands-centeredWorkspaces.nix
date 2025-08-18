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
          "custom/weather"
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
            "1" = "";
          };
          format = "{icon}";
          format-icons = {
            "1" = "";
            "3" = "";
            "5" = "󰎞";
            "default" = "󰝦";
            "urgent" = "";
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
            "2" = "";
          };
          format = "{icon}";
          format-icons = {
            "2" = "";
            "4" = "";
            "6" = "";
            "default" = "󰝦";
            "urgent" = "";
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
          format = "{:%I:%M %p}";
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
          format = "{temperatureC}° 󰔏";
          tooltip = false;
          critical-threshold = 80;
          format-critical = "{temperatureC}° 󰸁";
        };

        cpu = {
          interval = 5;
          format = "{usage}% 󰻠";
          tooltip = true;
        };

        memory = {
          interval = 5;
          format = "{used}G 󰍛";
          tooltip = false;
        };

        backlight = {
          format = "󰖨 {percent}%";
        };

        pulseaudio = {
          scroll-step = 2;
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-bluetooth-muted = "󰝟";
          format-muted = "󰝟";
          format-source = "";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
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
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󱘖 {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
          ];
          on-click = "";
          tooltip = false;
        };

        #====================CUSTOM MODULES====================
        "custom/exit" = {
          tooltip = false;
          format = "";
          on-click = "sleep 0.1 && wlogout";
        };

        "custom/hyprbindings" = {
          tooltip = false;
          format = "�ｴ";
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
            "notification" = " 󱕫";
            "none" = "";
            "dnd-notification" = " ";
            "dnd-none" = "󰂛";
            "inhibited-notification" = " ";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = " ";
            "dnd-inhibited-none" = "";
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
          format = "";
          on-click = "sleep 0.1 && if pgrep -x \"rofi\" > /dev/null; then killall rofi; else rofi -show drun; fi";
        };

        "custom/weather" = {
          format = "{}";
          tooltip = true;
          interval = 600;
          exec = "wttrbar --main-indicator 'temp_F' --date-format '%Y-%m-%d' --custom-indicator '{ICON} {temp_F}°'";
          return-type = "json";
          on-click = "sleep 0.1 && xdg-open 'https://wttr.in'";
        };
      }
    ];
  };
}
