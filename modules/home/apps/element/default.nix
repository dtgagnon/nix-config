{ lib
, pkgs
, config
, namespace
, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.apps.element;
in {
  options.${namespace}.apps.element = {
    enable = mkEnableOption "Element Matrix client";
  };

  config = mkIf cfg.enable {
    programs.element-desktop = {
      enable = true;
      # Tell Electron to use gnome-keyring for secure credential storage
      package = pkgs.element-desktop.override {
        commandLineArgs = "--password-store=gnome-libsecret";
      };
    };
  };
}
