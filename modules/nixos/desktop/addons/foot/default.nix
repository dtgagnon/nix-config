{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.foot;
in
{
  options.${namespace}.desktop.addons.foot = {
    enable = mkBoolOpt false "Whether to enable the gnome file manager.";
  };

  config = mkIf cfg.enable {
    spirenix.desktop.addons.term = {
      enable = true;
      pkg = pkgs.foot;
    };

    spirenix.user.home.configFile."foot/foot.ini".source = ./foot.ini;
  };
}
