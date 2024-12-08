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
        font-size: 20px;
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
        font-size: 24px;
        padding: 0 16px 0 4px;
        margin: 0 2px;
        background: #${colors.base00};
        border-radius: 12px;
        border: 2px solid #${colors.base03};
      }

      #workspaces {
        padding: 0 8px;
        margin: 0 2px;
        background: #${colors.base00};
        border-radius: 12px;
        border: 2px solid #${colors.base03};
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
        padding: 0 8px;
        background: #${colors.base00};
        border: 2px solid #${colors.base03};
        border-radius: 12px;
      }

      /* ---------------Right--------------- */
      #waybar .modules-right {
        margin: 8px 12px;
      }
      
      #pulseaudio {
        margin: 0 2px;
        padding: 0 16px 0 8px;
        background: #${colors.base00};
        border: 2px solid #${colors.base03};
        border-radius: 12px;
      }

      #hardware {
        margin: 0 2px;
        padding: 0 12px 0 6px;
        background: #${colors.base00};
        border: 2px solid #${colors.base03};
        border-radius: 12px;
      }

      #cpu, #memory, #network {
        padding: 0 8px;
      }

      #temperature {
        padding: 0 4px 0 -4px;
      }
      
      #utilities {
        margin: 0 2px;
        padding: 0 12px;
        background: #${colors.base00};
        border: 2px solid #${colors.base03};
        border-radius: 12px;
      }

      #custom-exit {
        margin: 0;
        padding: 0 8px;
      }
    '';
  };
}