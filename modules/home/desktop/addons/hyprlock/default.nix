{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkForce;
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
      sourceFirst = true;
      settings = mkForce {
        background = [
          {
            monitor = "";
            path = "${config.stylix.image}";
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
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "${config.stylix.base16Scheme.base01}";
            font_color = "rgba(0, 0, 0, 1.0)"; # White for dots
            fade_on_empty = false;
            rounding = -1;
            check_color = "${config.stylix.base16Scheme.base0E}";
            placeholder_text = "Keep trying your best...";
            hide_input = false;
            position = "0, -400";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          # Date
          {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%A, %B %d")"'';
            color = "${config.stylix.base16Scheme.base01}";
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
            color = "${config.stylix.base16Scheme.base01}";
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
            path = "${pkgs.spirenix.profile-pics.dtgagnon}";
            size = 170;
            border_size = 2;
            border_color = "${config.stylix.base16Scheme.base01}";
            position = "0, -100";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
