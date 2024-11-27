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
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";
      control-center-margin-top = 0;
      control-center-margin-bottom = 0;
      control-center-margin-right = 0;
      control-center-margin-left = 0;
      notification-2fa-action = true;
      notification-inline-replies = false;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
    } "Swaync configuration options.";
    
    extraCSS = mkOpt types.str "" "Custom CSS for styling swaync.";
  };

  config = mkIf cfg.enable {
    services.swaync = {
      enable = true;
      systemd = cfg.systemd;
      settings = cfg.settings;
      style = builtins.readFile ./swaync.css + cfg.extraCSS;
    };
  };
}
