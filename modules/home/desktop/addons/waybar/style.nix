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
    programs.waybar.style = ''
      ${cfg.extraStyle}

      * {
        font-family: JetBrainsMono Nerd Font Mono;
        font-size: 18px;
        min-height: 0px;
        border: none;
        border-radius: 0;
        margin: 0;
        padding: 0;
      }

      window#waybar {
        background: transparent;
        color: #${colors.base05};
        border: none;
      }

      /* ---------------Left--------------- */

      #custom-startmenu {
        color: #${colors.base05};
        background: #${colors.base01};
        font-size: 32px;
        margin: 0;
        padding: 0;
        border-radius: 0 20px 0 20px;
      }

      #custom-hyprbindings {
        font-weight: bold;
        padding: 0;
        background: #${colors.base01};
        color: #${colors.base05};
        border-radius: 0;
      }

      #workspaces {
        background: #${colors.base00};
        color: #${colors.base05};
        margin: 4px 4px;
        padding: 5px 5px;
        border-radius: 16px;
      }

      #workspaces button {
        padding: 0;
        margin: 0;
        border-radius: 8px;
        color: #${colors.base05};
        background: #${colors.base01};
        opacity: 0.7;
      }

      #workspaces button.active {
        font-weight: bold;
        padding: 0;
        margin: 0;
        border-radius: 8px;
        color: #${colors.base05};
        background: #${colors.base01};
        opacity: 1.0;
        min-width: 20px;
      }

      #tray {
        font-weight: bold;
        padding: 0;
        background: #${colors.base01};
        color: #${colors.base05};
        border-radius: 8px;
      }

      #window {
        font-weight: bold;
        color: #${colors.base05};
      }

      /* ---------------Center--------------- */

      #custom-notification {
        font-weight: bold;
        color: #${colors.base05};
        background: #${colors.base05};
        margin: 0;
        padding: 0;
        border-radius: 20px 0px 0 20px;
      }

      #clock {
        padding: 0 5px;
        background: #${colors.base04};
        color: #${colors.base05};
        border-radius: 0 20px 20px 0;
      }

      /* ---------------Right--------------- */

      #idle_inhibitor {
        padding: 0 5px;
        border-radius: 20px 0 0 20px;
        color: #${colors.base05};
      }

      #battery, #memory, #cpu, #temperature, #backlight, #pulseaudio, #network {
        padding: 0 5px;
        color: #${colors.base05};
      }

      #custom-exit {
        border-radius: 0 20px 20px 0;
        color: #${colors.base05};
      }
    '';
  };
}
