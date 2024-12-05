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
  # imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.desktop.addons.waybar = {
    enable = mkBoolOpt false "Enable waybar";
    extraStyle = mkOpt types.str "" "Additional style to add to waybar";
  };

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
            "custom/hyprbindings"
            "hyprland/workspaces"
            "tray"
          ];
          modules-center = [
            "custom/notification"
            "clock"
          ];
          modules-right = [
            "idle_inhibitor"
            "temperature"
            "cpu"
            "memory"
            "backlight"
            "battery"
            "pulseaudio"
            "network"
            "custom/exit"
          ];
          "hyprland/workspaces" = {
            format = "{icon}";
            sort-by-number = true;
            active-only = false;
            format-icons = {
              "1" = " 󰲌 ";
              "2" = "  ";
              "3" = " 󰎞 ";
              "4" = "  ";
              "5" = "  ";
              "6" = " 󰺵 ";
              "7" = "  ";
              urgent = "  ";
              focused = "  ";
              default = "  ";
            };
            on-click = "activate";
          };
          clock = {
            format = "   {:%a, %b. %d         %I:%M %p}";
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
                days = "<span color='#${colors.base06}'><b>{}</b></span>";
                weeks = "<span color='#${colors.base07}'><b>W{}</b></span>";
                weekdays = "<span color='#${colors.base08}'><b>{}</b></span>";
                today = "<span color='#${colors.base09}'><b><u>{}</u></b></span>";
              };
            };
          };

          "idle_inhibitor" = {
            format = " {icon} ";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };
          "temperature" = {
            interval = 5;
            format = "{temperatureC}°";
            tooltip = true;
            critical-threshold = 30;
            format-critical = "<span color='#${colors.base0E}'></span>{temperatureC}°";
          };
          "cpu" = {
            interval = 5;
            format = "   {usage}% ";
            tooltip = true;
          };
          "memory" = {
            interval = 5;
            format = "   {used}GB ";
            tooltip = true;
          };
          backlight = {
            format = "  {percent}%";
          };
          network = {
            interval = 2;
            format-wifi = "   {essid}";
            format-ethernet = " 󰈀  {bandwidthDownBytes}";
            format-disconnected = " 󱚵  ";
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
          "pulseaudio" = {
            scroll-step = 2;
            format = " {icon} {volume}% {format_source} ";
            format-bluetooth = " {volume}% {icon} {format_source} ";
            format-bluetooth-muted = " 󰝟 {icon} {format_source} ";
            format-muted = " 󰝟 {format_source} ";
            format-source = "  ";
            format-source-muted = "  ";
            format-icons = {
              headphone = "  ";
              hands-free = " 󰋎 ";
              headset = " 󰋎 ";
              phone = "  ";
              portable = "  ";
              car = "  ";
              default = [
                "  "
                "  "
                "  "
              ];
            };
            on-click = "sleep 0.1 && pavucontrol";
          };
          tray = {
            icon-size = 14;
            spacing = 8;
          };
          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = " {icon} {capacity}% ";
            format-charging = " 󰂄 {capacity}% ";
            format-plugged = " 󱘖 {capacity}% ";
            format-icons = [
              " 󰁺 "
              " 󰁻 "
              " 󰁼 "
              " 󰁽 "
              " 󰁾 "
              " 󰁿 "
              " 󰂀 "
              " 󰂁 "
              " 󰂂 "
              " 󰁹 "
            ];
            on-click = "";
            tooltip = false;
          };

          "custom/exit" = {
            tooltip = false;
            format = "   ";
            on-click = "sleep 0.1 && wlogout";
          };
          "custom/startmenu" = {
            tooltip = false;
            format = "  ";
            # exec = "rofi -show drun";
            on-click = "sleep 0.1 && rofi-launcher";
          };
          "custom/hyprbindings" = {
            tooltip = false;
            format = " 󱕴 ";
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
