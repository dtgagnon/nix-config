{ 
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf concatStrings;
  cfg = config.spirenix.desktop.addons.waybar;

  inherit (config.lib.stylix) colors;
in
{
  config = mkIf cfg.enable {
    programs.waybar.style = concatStrings [ ''
      ${cfg.extraStyle}
      * {
        font-family: "Iosevka Nerd Font Mono", sans-serif;
        font-size: 14px;
        min-height: 0;
        border: none;
        border-radius: 0;
        margin: 0;
        padding: 0;
      }
      
      window#waybar {
        background: ${colors.base00};
        color: ${colors.base02};
        border: none;
      }

/* ~~~~~~~~~~~Left Side~~~~~~~~~~~~~~~~ */

      #custom-startmenu {
        color: ${colors.base02};
        background: ${colors.backgroundAlt};
        font-size: 32px;
        margin: 0;
        padding: 0;
        border-radius: 0 0 0 40px;
      }

      #custom-hyprbindings {
        font-weight: bold;
        padding: 0;
        background: ${colors.base01};
        color: ${colors.base02};
        border-radius: 0;
      }

      #workspaces {
        background: ${colors.base00};
        color: ${colors.base02};
        margin: 4px 4px;
        padding: 5px 5px;
        border-radius: 16px;
      }

      #workspaces button {
        padding: 0px 5px;
        margin: 0px 3px;
        border-radius: 16px;
        color: ${colors.base02};
        background: ${colors.base01};
        opacity: 0.5;
      }

      #workspaces button.active {
        font-weight: bold;
        padding: 0px 5px;
        margin: 0px 3px;
        border-radius: 16px;
        color: ${colors.base02};
        background: ${colors.base01};
        opacity: 1.0;
        min-width: 40px;
      }

      #tray {
        font-weight: bold;
        padding: 0;
        background: ${colors.base01};
        color: ${colors.base02};
        border-radius: 0;
        justify-content: center;
      }

      #window {
        justify-content: center;
        font-weight: bold;
        color: ${colors.base02};
      }

/* ~~~~~~~~~~~Center~~~~~~~~~~~~~~~~ */

      #custom-notification {
        font-weight: bold;
        color: ${colors.base02};
        background: ${colors.primary};
        margin: 0;
        padding: 0;
        border-radius: 0 0 0 40px;
      }

      #clock {
        padding: 0 5px;
        background: ${colors.base04};
        color: ${colors.base02};
        border-radius: 0;
      }

/* ~~~~~~~~~~~Right side~~~~~~~~~~~~~~~~ */

      #idle_inhibitor {
        padding: 0 5px;
        border-radius: 0 0 0 40px;
        color: ${colors.base02};
      }

      #battery, #memory, #cpu, #temperature, #backlight, #pulseaudio, #network {
        padding: 0 5px;
        color: ${colors.base02};
      }

      #custom-exit {
        border-radius: 0 40px 0 0;
        color: ${colors.base02};
      }

    ''];
  };
}
