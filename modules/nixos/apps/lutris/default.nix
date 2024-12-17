{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.lutris;
in
{
  options.${namespace}.apps.lutris = {
    enable = mkBoolOpt false "Enable lutris";
    games = mkOpt (types.listOf types.str) [ ] "Games to install";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lutris ];
  };
}
