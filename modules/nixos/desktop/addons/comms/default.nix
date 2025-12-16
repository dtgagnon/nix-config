{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.comms;
in
{
  options.${namespace}.desktop.addons.comms = {
    enable = mkBoolOpt false "Enable stand-alone communications modules (blueman, networkmanager)";
    network = mkBoolOpt true "Enable NetworkManager";
    bluetooth = mkBoolOpt true "Enable blueman for bluetooth management";
  };

  config = mkIf cfg.enable {
    # Add applets only when the corresponding feature is enabled
    environment.systemPackages =
      lib.optionals cfg.network [ pkgs.networkmanagerapplet ]
      ++ lib.optionals cfg.bluetooth [ pkgs.blueman ];
  };
}
