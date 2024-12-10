{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (config.lib.stylix) colors;
  cfg = config.${namespace}.desktop.addons.waybar;
in
{
  config = mkIf (cfg.presetLayout == "top-isolated-islands-centeredWorkspaces") {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = [
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
          "group/hardware" = {
            orientation = "inherit";
            modules = [
              "network"
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

          "group/utilities" = {
            orientation = "inherit";
            modules = [
              "custom/exit"
            ];
          };

##### 󰲌   󰎞   󰺵  󰝦    #####
          "hyprland/workspaces#odds" = {
            persistent-workspaces = {
              "1" = "";
              "3" = "";
              "5" = "󰎞";
            };
            format = "{icon}";
            format-icons = {
              "1" = "";
              "3" = "";
              "5" = "󰎞";
              "default" = "󰝦";
              "urgent" = "";
            };
            on-click = "activate";
						ignore-workspaces = [
							"2"
							"4"
							"6"
              "8"
              "10"
						];
          };

          "hyprland/workspaces#evens" = {
            persistent-workspaces = {
              "2" = "";
              "4" = "";
              "6" = "󰺵";
            };
            format = "{icon}";
            format-icons = {
              "2" = "";
              "4" = "";
              "6" = "󰺵";
              "default" = "󰝦";
              "urgent" = "";
            };
            on-click = "activate";
						ignore-workspaces = [
							"1"
							"3"
							"5"
              "7"
              "9"
						];
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
                weeks = "<span color='#${colors.base07}'>W{}</span>";
                weekdays = "<span color='#${colors.base08}'>{}</span>";
                today = "<span color='#${colors.base09}'><b><u>{}</u></b></span>";
              };
            };
          };

          temperature = {
            interval = 5;
            format = "{temperatureC}°";
            tooltip = true;
            critical-threshold = 30;
            format-critical = "<span color='#${colors.base0E}'></span>{temperatureC}°";
          };

          cpu = {
            interval = 5;
            format = "  {usage}<small>%</small>";
            tooltip = true;
          };

          memory = {
            interval = 5;
            format = " {used}<small>G</small>";
            tooltip = true;
          };

          backlight = {
            format = " {percent}%;";
          };

          network = {
            interval = 5;
            format-wifi = " {essid}";
            format-ethernet = "󰈀";
            format-disconnected = "󱚵";
            tooltip = true;
            tooltip-format = ''
              {ifname}
              {ipaddr}/{cidr}
              {signalstrength}
              Up: {bandwidthUpBytes}
              Down: {bandwidthDownBytes}
            '';
            tooltip-format-ethernet = ''
              {ipaddr}/{cidr}
              Up: {bandwidthUpBytes}
              Down: {bandwidthDownBytes}
            '';
          };

          pulseaudio = {
            scroll-step = 2;
            format = "{volume}<small>%</small> {format_source} {icon}";
            format-bluetooth = "{volume}<small>%</small> {format_source} {icon}";
            format-bluetooth-muted = "{format_source} 󰝟 {icon}";
            format-muted = "{format_source} 󰝟";
            format-source = "";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "󰋎";
              headset = "󰋎";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "sleep 0.1 && pavucontrol";
          };

          tray = {
            icon-size = 16;
            spacing = 8;
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon}{capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󱘖 {capacity}%";
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            on-click = "";
            tooltip = false;
          };

#====================CUSTOM MODULES====================
          "custom/exit" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && wlogout";
          };

          "custom/hyprbindings" = {
            tooltip = false;
            format = "󱕴";
            on-click = "sleep 0.1 && list-hypr-bindings";
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
              "notification" = "<span foreground='red'><sup>󱅫</sup></span>";
              "none" = "";
              "dnd-notification" = "<span foreground='red'><sup></sup></span>";
              "dnd-none" = "󰂛";
              "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
              "inhibited-none" = "";
              "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
              "dnd-inhibited-none" = " ";
            };
            return-type = "json";
            exec-if = "which makoctl";
            exec = "makoctl list -t | jq --unbuffered --compact-output '[.[0] // {}] | if length > 0 then {\"alt\":\"notification\", \"tooltip\": (.[0].summary + \":\\n\" + .[0].body)} else {\"alt\":\"none\"} end'";
            on-click = "makoctl invoke";
            on-click-right = "sleep 0.1 && makoctl dismiss";
            escape = true;

            interval = 5;
          };

          "custom/startmenu" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && rofi -show drun";
          };
        }
			];
    };
  };
}
