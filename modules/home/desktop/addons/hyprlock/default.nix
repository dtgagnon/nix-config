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
  cfg = config.${namespace}.desktop.addons.hyprlock;
in
{
  options.${namespace}.desktop.addons.hyprlock = {
    enable = mkBoolOpt false "Enable Hyprlock configuration";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        background = [
          {
            # monitor = "";
            path = "${config.stylix.image}";
            # color = "rgba(0, 0, 0, 0)";
            blur_passes = 2;
            blur_size = 4;
            contrast = 1;
            brightness = 0.5;
            vibrancy = 0.2;
            vibrancy_darkness = 0.2;
          }
        ];

        general = {
          no_fade_in = true;
          no_fade_out = true;
          hide_cursor = false;
          grace = 0;
          disable_loading_bar = true;
        };

        input-field = [
          {
            monitor = "";
            size = "250, 60";
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.35;
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";  # Transparent outer color
            inner_color = "rgba(90, 40, 90, 0.5)";  # Dark soft purple for input field background
            font_color = "rgba(242, 243, 244, 1)";  # White for dots
            fade_on_empty = false;
            rounding = -1;
            check_color = "rgba(190, 150, 200, 1)";  # Light purple for the checkmark
            placeholder_text = "<i><span foreground=\"#cdd6f4\">Input Password...</span></i>";
            hide_input = false;
            position = "0, -400";
            halign = "center";
            valign = "center";
          };
        ];

        label = [
          # Date
          {
            monitor = "";
            text = cmd[update:1000] echo "$(date +"%A, %B %d")"
            color = "rgba(145, 105, 160, 0.75)";  # Soft muted purple for date text
            font_size = 22;
            font_family = "JetBrains Mono";
            position = "0, 300";
            halign = "center";
            valign = "center";
          }

          # Time
          {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%-I:%M")"'';
            color = "rgba(145, 105, 160, 0.75)";  # Soft muted purple for time text
            font_size = 95;
            font_family = "JetBrains Mono Extrabold";
            position = "0, 200";
            halign = "center";
            valign = "center";
          }
        ];

        image = [
          # Profile picture
          {
            monitor = "";
            path = "${config.stylix.image}";
            size = 170;
            border_size = 2;
            border_color = "rgba(145, 105, 160, 0.75)";
            position = "0, -100";
            halign = "center";
            valign = "center";
          }

          # Desktop environment icon
          {
            monitor = "";
            # path = "${config.stylix.image}"; #replace with hyprland logo
            size = 75;
            border_size = 2;
            border_color = "rgba(145, 105, 160, 1.0)";
            position = "-50, -50";
            halign = "right";
            valign = "bottom";
          }
        ];
      };
    };
  };
}
