{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.swaylock;
in
{
  options.${namespace}.desktop.addons.swaylock = {
    enable = mkBoolOpt false "Whether to enable swaylock.";
    
    daemonize = mkBoolOpt true "Whether to run as a daemon.";
    
    settings = mkOpt types.attrs {
      color = "000000";
      font = "monospace";
      indicator-idle-visible = true;
      indicator-radius = 100;
      line-color = "ffffff";
      show-failed-attempts = true;
    } "Swaylock configuration options.";
  };

  config = mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = cfg.settings;
    };

    security.pam.services.swaylock = {};
  };
}
