{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.gimp;
in
{
  options.${namespace}.apps.gimp = {
    enable = mkBoolOpt false "Enable GIMP image editor";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gimp-with-plugins ];
  };
}
