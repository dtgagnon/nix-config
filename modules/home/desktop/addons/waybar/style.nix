{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.addons.waybar;

  inherit (config.lib.stylix) colors;
in
{
  config = mkIf cfg.enable {
    programs.waybar.style = ''
      ${cfg.extraStyle}

      * {
        font-family: ${config.stylix.fonts.sansSerif.name};
        font-size: 16px;
        min-height: 0;
        border: none;
        border-radius: 0;
        margin: 0;
        padding: 0;
      }

      window#waybar {
        background: transparent;
        color: #${colors.base05};
      }

      /* ---------------Left--------------- */

      #waybar .modules-left {
        margin: 8px 12px;
      }

      #custom-startmenu {
        font-size: 20px;
        padding: 0 14px 0 4;
        margin: 0 2px;
        background: #${colors.base00};
        border-radius: 10px;
        border: 2px solid #${colors.base0C};
      }

      #workspaces {
        padding: 0 8px;
        margin: 0 2px;
        background: #${colors.base00};
        border-radius: 10px;
        border: 2px solid #${colors.base0C};
      }

      #workspaces button {
        opacity: 0.7;
        padding: 0 8px;
        margin: 0;
      }

      #workspaces .active {
        opacity: 1.0;
        margin: 0;
        padding: 0 8px;
      }

      /* ---------------Center--------------- */

      #waybar .modules-center {
        margin: 8px 0;
      }

      #clock {
        margin: 0;
        padding: 0 4px;
        background: #${colors.base00};
        border: 2px solid #${colors.base0C};
        border-radius: 10px;
      }

      /* ---------------Right--------------- */
      #waybar .modules-right {
        margin: 8px 12px;
      }

      #hardware {
        margin: 0 2px;
        padding: 0 20px;
        background: #${colors.base02};
        border: 2px solid #${colors.base0E};
        border-radius: 10px;
      }
      
      #utilities {
        margin: 0 2px;
        padding: 0 20px 0 0;
        background: #${colors.base02};
        border: 2px solid #${colors.base0E};
        border-radius: 10px;
      }

      #pulseaudio {
        margin: 0 2px;
        padding: 0 10px;
        background: #${colors.base02};
        border: 2px solid #${colors.base0E};
        border-radius: 10px;
      }
    '';
  };
}