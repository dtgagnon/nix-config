{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.waybar;

  inherit (config.lib.stylix) colors;
in
{
  options.${namespace}.desktop.addons.waybar = {
    enable = mkBoolOpt false "Enable waybar";
    waybarStyle = mkOpt types.str "top-isolated-islands" "The waybar style to use";
    extraStyle = mkOpt types.str "" "Additional style to add to waybar";
  };

  imports = [ ./styles/${cfg.waybarStyle}.nix ];

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.hyprpanel
      pkgs.ags
    ];

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = [
        {
          layer = "top";
          position = "top";
          margin = "0 0 0 0";
          modules-left = [
            "custom/startmenu"
            "hyprland/workspaces"
          ];
          modules-center = [
            "custom/notification"
            "clock"
          ];
          modules-right = [
            "pulseaudio"
            "group/hardware"
            "group/utilities"
          ];

# Custom grouping of modules
          "group/hardware" = {
            orientation = "inherit";
            modules = [
              "temperature"
              "cpu"
              "memory"
              "backlight"
              "battery"
              "network"
            ];
          };

          "group/utilities" = {
            orientation = "inherit";
            modules = [
              "tray"
              "custom/exit"
            ];
          };

          "hyprland/workspaces" = {
            format = "{icon}";
            sort-by-number = true;
            active-only = false;
            format-icons = {
              "1" = "󰲌";
              "2" = "";
              "3" = "󰎞";
              "4" = "";
              "5" = "";
              "6" = "󰺵";
              "7" = "";
              urgent = "";
              focused = "";
              default = "";
            };
            on-click = "activate";
          };


# Individual module configuration
          clock = {
            format = "{:%a, %b. %d   %I:%M <small>%p</small>}";
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
            format = "   {usage}<small>%</small>";
            tooltip = true;
          };

          memory = {
            interval = 5;
            format = "  {used}<small>G</small>";
            tooltip = true;
          };

          backlight = {
            format = "  {percent}%;";
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
            format = "{icon} {capacity}%";
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

          "custom/exit" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && wlogout";
          };

          "custom/startmenu" = {
            tooltip = false;
            format = "";
            on-click = "sleep 0.1 && rofi -show drun";
          };

          "custom/hyprbindings" = {
            tooltip = false;
            format = "󱕴";
            on-click = "sleep 0.1 && list-hypr-bindings";
          };

          "custom/notification" = {
            tooltip = false;
            format = "{summary} {icon}";
            "format-icons" = {
              notification = "<span foreground='red'><sup>󱅫</sup></span>";
              none = "";
              "dnd-notification" = "<span foreground='red'><sup></sup></span>";
              "dnd-none" = "󰂛";
              "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
              "inhibited-none" = "";
              "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
              "dnd-inhibited-none" = " ";
            };
            return-type = "json";
            exec = "makoctl list -t | jq '.[0] // {}'";
            interval = 5;
            on-click = "notify-send \"$(makoctl list -t | jq -r '.[0].summary')\" \"$(makoctl list -t | jq -r '.[0].body')\"";
            on-click-right = "sleep 0.1 && makoctl dismiss -a";
            escape = true;
          };
        }
      ];
    };
  };
}