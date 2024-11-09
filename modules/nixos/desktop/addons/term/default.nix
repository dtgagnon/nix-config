{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.term;
in
{
  options.${namespace}.desktop.addons.term = {
    enable = mkBoolOpt false "Whether to enable the gnome file manager.";
    pkg = mkOpt types.package pkgs.foot "The terminal to install.";
  };

  config = mkIf cfg.enable { environment.systemPackages = [ cfg.pkg ]; };
}
