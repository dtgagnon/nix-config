{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.firefox-nordic-theme;
in
{
  options.${namespace}.desktop.addons.firefox-nordic-theme = {
    enable = mkBoolOpt false "Whether to enable the Nordic theme for firefox.";
  };

  config = mkIf cfg.enable {
    spirenix.apps.firefox = {
      extraConfig = builtins.readFile "${pkgs.spirenix.firefox-nordic-theme}/configuration/user.js";
      userChrome = ''
        @import "${pkgs.spirenix.firefox-nordic-theme}/userChrome.css";
      '';
    };
  };
}
