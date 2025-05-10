{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.weylus;
in
{
  options.${namespace}.desktop.addons.weylus = {
    enable = mkBoolOpt false "Enable the weylus tablet-desktop mirroring and src input protocol";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.weylus ];
  };
}
