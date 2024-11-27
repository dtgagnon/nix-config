{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.wlogout;
in
{
  options.${namespace}.desktop.addons.wlogout = {
    enable = mkBoolOpt false "Whether to enable wlogout.";
    
    layout = mkOpt (types.listOf types.attrs) [
      {
        label = "lock";
        action = "swaylock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "logout";
        action = "loginctl terminate-user $USER";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ] "Layout configuration for wlogout buttons.";

    style = mkOpt types.str '''
      * {
        background-image: none;
      }
      window {
        background-color: rgba(12, 12, 12, 0.9);
      }
      button {
        color: #FFFFFF;
        background-color: #1E1E1E;
        border-style: solid;
        border-width: 2px;
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
      }
      button:focus, button:active, button:hover {
        background-color: #3700B3;
        outline-style: none;
      }
    ''' "CSS styling for wlogout.";
  };

  config = mkIf cfg.enable {
    programs.wlogout = {
      enable = true;
      layout = cfg.layout;
      style = cfg.style;
    };
  };
}
