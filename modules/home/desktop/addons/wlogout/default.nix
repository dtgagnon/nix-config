{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (config.lib.stylix) colors;
  cfg = config.${namespace}.desktop.addons.wlogout;

  iconsDir = "/home/${config.${namespace}.user.name}/.config/wlogout/icons";
in
{
  options.${namespace}.desktop.addons.wlogout = {
    enable = mkEnableOption "Enable wlogout screen for managing sessions.";
  };

  config = mkIf cfg.enable {
    programs.wlogout = {
      enable = true;
      layout = [
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
        }
        {
          label = "sleep";
          action = "loginctl lock-session && systemctl suspend";
          text = "Sleep";
          keybind = "h";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
        {
          label = "logout";
          action = "loginctl kill-session $XDG_SESSION_ID";
          text = "Logout";
          keybind = "e";
        }
      ];
      style = ''
        *{
          background-image: none;
          box-shadow: none;
          text-shadow: none;
          transition 20ms;

        }

        window {
          font-family: JetbrainsMono Nerd Font;
          font-style: italic;
          font-size: 20px;
          color: #${colors.base05};
          background-color: #${colors.base00}80;
        }

        button {
          color: #${colors.base05};
          font-size: 20px;
          background-repeat: no-repeat;
          background-position: center;
          background-size: 25%;
          background-color: #${colors.base01};
          border-style: solid;
          border-radius: 20px;
          border: 2px solid #${colors.base03};
          animation: gradient_f 20s ease-in infinite;
          transition: all 0.3s ease-in-out;
          margin: 10px;
        }

        button:focus, button:active {
          background-color: #${colors.base02};
          border: 2px solid #${colors.base08};
          color: #${colors.base04}
        }

        button:hover {
          background-color: #${colors.base02};
          border: 2px solid #${colors.base0D};
          color: #${colors.base04};
        }

        #shutdown {
          background-image: image(url("${iconsDir}/shutdown.png"));
        }
        #reboot {
          background-image: image(url("./icons/reboot.png"));
        }
        #logout {
          background-image: image(url("${iconsDir}/logout.png"));
        }
        #sleep {
          background-image: image(url("./icons/hibernate.png"));
        }
      '';

    };

    xdg.configFile."wlogout/icons" = {
      recursive = true;
      source = ./icons;
    };

    spirenix.desktop.hyprland.extraWinRules.layerrule = [
      "blur, logout_dialog"
    ];
  };
}
