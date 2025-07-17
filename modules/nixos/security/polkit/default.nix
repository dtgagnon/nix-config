{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.security.polkit;
in
{
  options.${namespace}.security.polkit = {
    enable = mkEnableOption "Enable polkit customizations";
  };

  config = mkIf cfg.enable {
    security.polkit = {
      enable = true;
    };
  };
}
