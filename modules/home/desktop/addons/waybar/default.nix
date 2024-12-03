{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.waybar;

  customTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
in {
  options.${namespace}.desktop.addons.waybar = {
    enable = mkBoolOpt false "Enable waybar";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.hyprpanel
      pkgs.ags
    ];

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      # style = "???";
      settings = [
        {
          layer = "top";
          position = "top";
          margin = "0 0 0 0";
          modules-left = [
            "custom/startmenu"
            "hyprland/workspaces"
            "tray"
          ];
          modules-center = [
            "custom/notification"
            "clock"
          ];
          modules-right = [
            "idle_inhibitor"
            "cpu"
            "memory"
            "gpu"
            "backlight"
            "battery"
            "pulseaudio"
            "network"
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
            format = "  {:%a, %b %d    %I:%M %p}";
            interval = 1;
            tooltip-format = "<tt>{calendar}</tt>";
            calendar = {
              mode = "month";
              "mode-mon-col" = 3;
              "weeks-pos" = "right";
              "on-scroll" = 1;
              "on-click-right" = "mode";
              format = {
                months = "<span color='#cba6f7'><b>{}</b></span>";
                days = "<span color='#b4befe'><b>{}</b></span>";
                weeks = "<span color='#89dceb'><b>W{}</b></span>";
                weekdays = "<span color='#f2cdcd'><b>{}</b></span>";
                today = "<span color='#f38ba8'><b><u>{}</u></b></span>";
              };
            };
          };
          "custom/notification" = {
            tooltip = false;
            format = "{} {icon}";
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
            "return-type" = "json";
            "exec-if" = "which swaync-client";
            exec = "swaync-client -swb";
            "on-click" = "sleep 0.1 && swaync-client -t -sw";
            "on-click-right" = "sleep 0.1 && swaync-client -d -sw";
            escape = true;
          };
          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "  ";
              deactivated = "  ";
            };
          };
          backlight = {
            format = " {percent}%";
          };
          battery = {
            states = {
              good = 80;
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-alt = "{time}";
            format-charging = "  {capacity}%";
            format-icons = ["󰁻 " "󰁽 " "󰁿 " "󰂁 " "󰂂 "];
          };
          network = {
            interval = 1;
            format-wifi = "  {essid}";
            format-ethernet = "󰈀 ";
            format-disconnected = " 󱚵  ";
            tooltip-format = ''
              {ifname}
              {ipaddr}/{cidr}
              {signalstrength}
              Up: {bandwidthUpBits}
              Down: {bandwidthDownBits}
            '';
          };
          pulseaudio = {
            scroll-step = 2;
            format = "{icon}  {volume}% ";
            format-bluetooth = " {icon} {volume}% ";
            format-muted = "  ";
            format-icons = {
              headphone = "  ";
              headset = "  ";
              default = ["  " "  "];
            };
          };
          tray = {
            icon-size = 16;
            spacing = 8;
          };
        }
      ];
    };
  };
}
