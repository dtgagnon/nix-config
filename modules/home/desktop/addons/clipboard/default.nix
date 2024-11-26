{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.clipboard;
in
{
  options.${namespace}.desktop.addons.clipboard = {
    enable = mkBoolOpt false "Clipboard";
  };

  config = mkIf cfg.enable { 
    home.packages = [ pkgs.wl-clipboard ];
  };
}
