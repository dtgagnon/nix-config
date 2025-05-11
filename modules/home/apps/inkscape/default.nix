{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.inkscape;
in
{
  options.${namespace}.apps.inkscape = {
    enable = mkBoolOpt false "Enable Inkscape vector illustration application";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.inkscape ];
  };
}
