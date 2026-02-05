{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption optionalString;
  cfg = config.${namespace}.desktop.addons.wlogout;

  stylixEnabled = config.stylix.enable or false;
  colors = if stylixEnabled then config.lib.stylix.colors else {};

  iconsDir = "/home/${config.${namespace}.user.name}/.config/wlogout/icons";

  # Base style without colors (icons only)
  baseStyle = ''
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
    }

    button {
      font-size: 20px;
      background-repeat: no-repeat;
      background-position: center;
      background-size: 25%;
      border-style: solid;
      border-radius: 20px;
      animation: gradient_f 20s ease-in infinite;
      transition: all 0.3s ease-in-out;
      margin: 10px;
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

  # Stylix color additions
  stylixStyle = ''
    window {
      color: #${colors.base05};
      background-color: #${colors.base00}80;
    }

    button {
      color: #${colors.base05};
      background-color: #${colors.base01};
      border: 2px solid #${colors.base03};
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
  '';
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
      style = baseStyle + optionalString stylixEnabled stylixStyle;
    };

    xdg.configFile."wlogout/icons" = {
      recursive = true;
      source = ./icons;
    };

    spirenix.desktop.hyprland.extraWinRules.layerrule = [
      {
        name = "wlogout-blur";
        "match:namespace" = "logout_dialog";
        blur = true;
      }
    ];
  };
}
