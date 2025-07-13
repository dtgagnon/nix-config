{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.wlogout;
in {
  options.${namespace}.desktop.addons.wlogout = {
    enable = mkBoolOpt false "Enable wlogout screen for managing sessions.";
  };

  config = mkIf cfg.enable {
    programs.wlogout = {
      enable = true;
      style = ''
        *{
          font-family: JetbrainsMono Nerd Font;
          font-style: italic;
          font-size: 20px;
        }
        
        window {
            color: #d3c6aa; /* text */
            background-color: rgba(39, 46, 51, 0.5);
        
        } 
        
        button {
            background-repeat: no-repeat;
            background-position: center;
            background-size: 20%;
            background-color: transparent;
            animation: gradient_f 20s ease-in infinite;
            transition: all 0.3s ease-in;
            box-shadow: 0 0 10px 2px transparent;
            border-radius: 36px;
            margin: 10px;
        }
        
        
        button:focus {
            box-shadow: none;
            outline-style: none;
            background-size : 20%;
        }
        
        button:hover {
            background-size: 50%;
            outline-style: none;
            box-shadow: 0 0 10px 3px rgba(0,0,0,.4);
            background-color: #83c092;
            color: transparent;
            transition: all 0.3s cubic-bezier(.55, 0.0, .28, 1.682), box-shadow 0.5s ease-in;
        }
        
        #shutdown {
            background-image: image(url("./icons/power.png"));
        }
        #shutdown:hover {
          background-image: image(url("./icons/power-hover.png"));
        }
        
        #logout {
            background-image: image(url("./icons/logout.png"));
        
        }
        #logout:hover {
          background-image: image(url("./icons/logout-hover.png"));
        }
        
        #reboot {
            background-image: image(url("./icons/restart.png"));
        }
        #reboot:hover {
          background-image: image(url("./icons/restart-hover.png"));
        }
        
        #lock {
            background-image: image(url("./icons/lock.png"));
        }
        #lock:hover {
          background-image: image(url("./icons/lock-hover.png"));
        }
        
        #sleep {
            background-image: image(url("./icons/hibernate.png"));
        }
        #sleep:hover {
          background-image: image(url("./icons/hibernate-hover.png"));
        }
      '';
      layout = [
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
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
        {
          label = "sleep";
          action = "loginctl lock-session && systemctl suspend";
          text = "Sleep";
          keybind = "h";
        }
        {
          label = "lock";
          action = "loginctl lock-session";
          text = "Lock";
          keybind = "l";
        }
      ];
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