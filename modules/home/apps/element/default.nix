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
  };
}
