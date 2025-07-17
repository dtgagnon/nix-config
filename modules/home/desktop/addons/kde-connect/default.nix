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

    # spirenix.desktop.hyprland.extraExec = mkIf config.spirenix.desktop.hyprland.enable [
    #   "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect"
    #   "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
    # ];
  };
}
