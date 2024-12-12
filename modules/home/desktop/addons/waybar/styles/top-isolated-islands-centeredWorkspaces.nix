{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.lib.stylix) colors;
  cfg = config.${namespace}.desktop.addons.waybar;

  core = config.spirenix.desktop.styling.core;
in
{
  config = mkIf (cfg.presetStyle == "top-isolated-islands-centeredWorkspaces") {
    programs.waybar.style = ''
      ${cfg.extraStyle}

      * {
      	font-family: ${core.fonts.monospace.name};
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

      #audioControl {
      	margin: 0 2px;
      	padding: 0 16px;
      	background: #${colors.base00};
      	border: 2px solid #${colors.base03};
      	border-radius: 12px;
      }

      #custom-music {
      	font-family: ${core.fonts.sansSerif.name};
      	font-size: 20px;
      }

      #pulseaudio {
      	padding: 0 8px 0 16px;
      }

      #hardware {
				font-size: 20px;
      	margin: 0 2px;
      	padding: 0 12px 0 0;
      	background: #${colors.base00};
      	border: 2px solid #${colors.base03};
      	border-radius: 12px;
      }

      #cpu, #memory, #network {
      	padding: 0 8px;
      }

      #temperature {
				padding: 0 4px 0 0;
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


      /* ---------------Center--------------- */

      #waybar .modules-center {
      	margin: 8px 0;
      }

      #custom-startmenu {
      	padding: 0 8px;
      	margin: 0 2px;
      	background: #${colors.base00};
      	border-radius: 12px;
      	border: 2px solid #${colors.base03};
      }

      #workspaces.odds {
      	padding: 0 8px;
      	margin: 0 2px;
      	background: #${colors.base00};
      	border-radius: 12px;
      	border: 2px solid #${colors.base03};
      }

      #workspaces.odds button {
      	opacity: 0.40;
      	padding: 0 8px;
      	margin: 0;
      }

      #workspaces.odds button:hover {
      	text-shadow: inherit;
      	box-shadow: inherit;
      	transition: border-color 0.3s, color 0.3s;
      	color: #${colors.base05};
      }

      #workspaces.odds .active {
      	opacity: 1.0;
      	margin: 0;
      	padding: 0 8px;
      }

      #workspaces.evens {
      	padding: 0 8px;
      	margin: 0 2px;
      	background: #${colors.base00};
      	border-radius: 12px;
      	border: 2px solid #${colors.base03};
      }

      #workspaces.evens button {
      	opacity: 0.40;
      	padding: 0 8px;
      	margin: 0;
      }

      #workspaces.evens button:hover {
      	text-shadow: inherit;
      	box-shadow: inherit;
      	transition: border-color 0.3s, color 0.3s;
      	color: #${colors.base03};
      }

      #workspaces.evens .active {
      	opacity: 1.0;
      	margin: 0;
      	padding: 0 8px;
      }

      /* ---------------Right--------------- */

      #waybar .modules-right {
      	margin: 8px 12px;
      }

      #clock#clock {
      	font-family: ${core.fonts.sansSerif.name};
      	font-size: 20px;
      	margin: 0 2px;
      	padding: 0 8px;
      	background: #${colors.base00};
      	border: 2px solid #${colors.base03};
      	border-radius: 12px;
      }

      #clock#calendar {
      	font-family: ${core.fonts.sansSerif.name};
      	font-size: 20px;
      	margin: 0 2px;
      	padding: 0 8px;
      	background: #${colors.base00};
      	border: 2px solid #${colors.base03};
      	border-radius: 12px;
      }

      #tray {
      	margin: 0 2px;
      	padding: 0 8px;
      	background: #${colors.base00};
      	border: 2px solid #${colors.base03};
      	border-radius: 12px;
      }
    '';
  };
}
