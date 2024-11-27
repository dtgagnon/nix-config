{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.swaync;
in
{
  options.${namespace}.desktop.addons.swaync = {
    enable = mkBoolOpt false "Whether to enable swaync notification center.";
    
    systemd = mkBoolOpt true "Whether to enable systemd integration.";
    
    settings = mkOpt types.attrs {
      positionX = "right";
      positionY = "top";
      control-center-margin-top = 10;
      control-center-margin-bottom = 10;
      control-center-margin-right = 10;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = true;
      control-center-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = true;
      hide-on-action = true;
    } "Swaync configuration options.";
    
    style = mkOpt types.str "" "Custom CSS for styling swaync.";
  };

  config = mkIf cfg.enable {
    services.swaync = {
      enable = true;
      systemd = cfg.systemd;
      settings = cfg.settings;
      style = cfg.style;
    };
  };
}
