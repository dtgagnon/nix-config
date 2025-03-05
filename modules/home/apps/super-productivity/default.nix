{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.super-productivity;
in
{
  options.${namespace}.apps.super-productivity = {
    enable = mkBoolOpt false "Enable super-productivity application module";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.super-productivity ];
  };
}
