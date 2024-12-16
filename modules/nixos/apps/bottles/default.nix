{ 
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.bottles;
in
{
  options.${namespace}.apps.bottles = {
    enable = mkBoolOpt false "Enable bottles module";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.bottles ];
  };
}