{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.home-manager;
in
{
  options.${namespace}.cli.home-manager = {
    enable = mkBoolOpt true "home-manager";
  };

  config = mkIf cfg.enable {
    programs.home-manager.enable = true; 
  };
}
