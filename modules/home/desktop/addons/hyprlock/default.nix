{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkForce optionalAttrs;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.hyprlock;

  stylixEnabled = config.stylix.enable;
  colors = if stylixEnabled then config.lib.stylix.colors else {};
in
{
  options.${namespace}.desktop.addons.hyprlock = {
    enable = mkBoolOpt false "Enable Hyprlock configuration";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      sourceFirst = true;
      settings = mkForce {
        background = [
          {
            monitor = "";
            path = "${config.spirenix.desktop.styling.core.wallpaper}";
            color = "rgba(0, 0, 0, 0)";
            blur_passes = 2;
            blur_size = 4;
            contrast = 1;
            brightness = 0.5;
            vibrancy = 0.2;
            vibrancy_darkness = 0.2;
          }
        ];

        general = {
          hide_cursor = false;
          ignore_empty_input = true;
        };

        input-field = [
          ({
            monitor = "";
            size = "250, 60";
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.35;
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";
            font_color = "rgba(0, 0, 0, 1.0)"; # White for dots
            fade_on_empty = false;
            rounding = -1;
            placeholder_text = "Keep trying your best...";
            hide_input = false;
            position = "0, -400";
            halign = "center";
            valign = "center";
          } // optionalAttrs stylixEnabled {
            inner_color = "rgb(${colors.base01})";
            check_color = "rgb(${colors.base0E})";
          })
        ];

        label = [
          # Date
          ({
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%A, %B %d")"'';
            font_size = 22;
            font_family = "JetBrains Mono";
            position = "0, 300";
            halign = "center";
            valign = "center";
          } // optionalAttrs stylixEnabled {
            color = "rgb(${colors.base01})";
          })

          # Time
          ({
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%-I:%M")"'';
            font_size = 95;
            font_family = "JetBrains Mono Extrabold";
            position = "0, 200";
            halign = "center";
            valign = "center";
          } // optionalAttrs stylixEnabled {
            color = "rgb(${colors.base01})";
          })
        ];

        image = [
          # Profile picture
          ({
            monitor = "";
            path = "${pkgs.spirenix.profile-pics.dtgagnon}";
            size = 170;
            border_size = 2;
            position = "0, -100";
            halign = "center";
            valign = "center";
          } // optionalAttrs stylixEnabled {
            border_color = "rgb(${colors.base01})";
          })
        ];
      };
    };
  };
}
