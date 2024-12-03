{ 
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf concatStrings;
  cfg = config.spirenix.desktop.addons.waybar;

  inherit (config.lib.stylix) colors;
  customTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
in
{
  config = mkIf cfg.enable {
    programs.waybar.style = concatStrings [ ''
      ${cfg.extraStyle}
      * {
        font-family: JetBrainsMono Nerd Font Mono;
        font-size: 16px;
        min-height: 0;
        border: none;
        border-radius: 0;
        margin: 0px;
        padding: 0px;
      }
      window#waybar {
        background: rgba(0,0,0,0);
      }
      #workspaces {
        color: #${colors.base00};
        background: #${colors.base01};
        margin: 4px 4px;
        padding: 5px 5px;
        border-radius: 16px;
      }
      #workspaces button {
        padding: 0px 5px;
        margin: 0px 3px;
        border-radius: 16px;
        color: #${colors.base00};
        background: linear-gradient(45deg, #${colors.base08}, #${colors.base0D});
        opacity: 0.5;
        transition: ${customTransition};
      }
      #workspaces button.active {
        font-weight: bold;
        padding: 0px 5px;
        margin: 0px 3px;
        border-radius: 16px;
        color: #${colors.base00};
        background: linear-gradient(45deg, #${colors.base08}, #${colors.base0D});
        transition: ${customTransition};
        opacity: 1.0;
        min-width: 40px;
      }
      #workspaces button:hover {
        font-weight: bold;
        border-radius: 16px;
        color: #${colors.base00};
        background: linear-gradient(45deg, #${colors.base08}, #${colors.base0D});
        opacity: 0.8;
        transition: ${customTransition};
      }
      tooltip {
        background: #${colors.base00};
        border: 1px solid #${colors.base08};
        border-radius: 12px;
      }
      tooltip label {
        color: #${colors.base08};
      }

      // Waybar left
      #custom-startmenu {
        color: #${colors.base0B};
        background: #${colors.base02};
        font-size: 28px;
        margin: 0px;
        padding: 0px 0px 0px 0px;
        border-radius: 0px 0px 0px 0px;
      }
      #custom-hyprbindings, #window, #tray {
        font-weight: bold;
        padding: 0px 0px;
        background: #${colors.base04};
        color: #${colors.base00};
        border-radius: 0px 0px 0px 0px;
      }

      // Waybar center
      #custom-notification, #clock {
        font-weight: bold;
        color: #${colors.base00};
        background: linear-gradient(90deg, #${colors.base0E}, #${colors.base0C});
        margin: 0px;
        padding: 0px 0px 0px 0px;
        border-radius: 0px 0px 0px 40px;
      }

      // Waybar right
      #idle_inhibitor, #cpu, #memory, #gpu, #network, #pulseaudio, #battery, #custom-exit {
        font-weight: bold;
        background: #${colors.base0F};
        color: #${colors.base00};
        margin: 0px 0px;
        border-radius: 0px 0px 0px 0px;
        padding: 0px 0px;
      }
    '' ];
  };
}
