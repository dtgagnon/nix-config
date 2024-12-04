{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.mako;
in
{
  options.${namespace}.desktop.addons.mako = {
    enable = mkBoolOpt false "Whether to enable Mako for wayland notification management";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.libnotify ];

    services.mako = {
      enable = true;
      borderRadius = 4;
      borderSize = 2;
      margin = "12,12,6";
      padding = "12,12,12,12";
      defaultTimeout = 5000;
      maxVisible = 3;
    };
  };
}
