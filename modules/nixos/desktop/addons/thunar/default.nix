{ lib, pkgs, config, namespace, ... }:

let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.thunar;
in
{
  options.${namespace}.desktop.addons.thunar = {
    enable = mkBoolOpt false "Whether to enable thunar file manager";
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
      plugins = [
        # thunar-archive-plugin
        # thunar-volman
      ];
    };
    programs.xfconf.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;
  };
}
