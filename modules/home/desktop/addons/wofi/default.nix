{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.wofi;
in
{
  options.${namespace}.desktop.addons.wofi = {
    enable = mkBoolOpt false "Whether to enable the Wofi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.wofi = {
      enable = true;
      settings = ./config;
      style = ./style.css;
    };
    home.packages = with pkgs; [
      wofi-emoji
    ];
  };
}
