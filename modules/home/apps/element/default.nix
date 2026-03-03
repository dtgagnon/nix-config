{ lib
, pkgs
, config
, namespace
, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types literalExpression;
  cfg = config.${namespace}.apps.element;
in {
  options.${namespace}.apps.element = {
    enable = mkEnableOption "Element Matrix client";
  };

  config = mkIf cfg.enable {
    programs.element-desktop = {
      enable = true;
    };

    # Tell Electron to use gnome-keyring for secure credential storage
    xdg.configFile."Element/argv.json".text = builtins.toJSON {
      password-store = "gnome-libsecret";
    };
  };
}
