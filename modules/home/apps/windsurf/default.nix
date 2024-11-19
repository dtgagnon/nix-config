{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.windsurf;
in
{
  options.${namespace}.apps.windsurf = {
    enable = mkBoolOpt false "Enable windsurf module";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.spirenix.windsurf ];
  };
}
