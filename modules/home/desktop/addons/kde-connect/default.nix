{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.kde-connect;
in
{
  options.${namespace}.desktop.addons.kde-connect = {
    enable = mkBoolOpt false "Enable KDE-connect for phone linking";
  };

  config = mkIf cfg.enable {
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };

    # qdbus6 is required by noctalia-shell's KDE Connect plugin to query the D-Bus daemon
    home.packages = [ pkgs.kdePackages.qttools ];
  };
}
