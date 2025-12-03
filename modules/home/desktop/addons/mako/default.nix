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
    home.packages = [
      pkgs.libnotify
      pkgs.jq
    ];

    services.mako = {
      enable = true;
      settings = {
        "default-timeout" = 5000;
        "ignore-timeout" = true; # ignore timeout set by application, uses default instead
        "max-visible" = 3;

        layer = "overlay";
        anchor = "top-center";
        width = 400;
        height = 82;
        margin = "2";
        padding = "12";

        "border-radius" = 12;
        "border-size" = 1;

        "max-icon-size" = 12;
      };
    };
  };
}
