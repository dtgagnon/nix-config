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

      #audioControl {
      	margin: 0 2px;
      	padding: 0 8px;
      	background: #${colors.base00};
      	border: 2px solid #${colors.base03};
      	border-radius: 12px;
      }

      #custom-music {
      	font-family: ${core.fonts.sansSerif.name};
      	font-size: 20px;
      }

      #pulseaudio {
      	padding: 0 16px 0 0;
      }

      #hardware {
      	margin: 0 2px;
      	padding: 0 12px 0 0;
      	background: #${colors.base00};
      	border: 2px solid #${colors.base03};
      	border-radius: 12px;
      }

      #cpu, #memory, #network {
      	padding: 0 10px;
      }

      #temperature {
				padding: 0;
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
      	background: linear-gradient(
					180deg,
					#${colors.base03} 0%,
					#${colors.base00} 50%,
					#${colors.base03} 100%
				);
      	border-radius: 12px;
      	border: 2px solid #${colors.base03};
        border-bottom: none;
				border-top: none;
      }

      #workspaces.odds button {
				background: transparent;
      	opacity: 0.30;
      	padding: 10px 8px;
      	margin: 0;
				border-radius: 4px;
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
				box-shadow: none;
      }

      #workspaces.odds .occupied {
        opacity: 0.7;
      }

      #workspaces.evens {
      	padding: 0 8px;
      	margin: 0 2px;
      	background: #${colors.base00};
      	border-radius: 12px;
      	border: 2px solid #${colors.base03};
        border-bottom: none;
				border-top: none;
      }

      #workspaces.evens button {
				background: transparent;
      	opacity: 0.30;
      	padding: 10px 8px;
      	margin: 0;
				border-radius: 4px;
      }

      #workspaces.evens button:hover {
      	text-shadow: inherit;
      	box-shadow: inherit;
				transition: border-color 0.3s, color 0.3s;
      	color: #${colors.base05};
      }

      #workspaces.evens .active {
      	opacity: 1.0;
      	margin: 0;
      	padding: 0 8px;
				box-shadow: none;
      }

      #workspaces.evens .occupied {
        opacity: 0.7;
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
