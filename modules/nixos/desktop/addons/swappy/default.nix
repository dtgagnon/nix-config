{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.swappy;
in
{
  options.${namespace}.desktop.addons.swappy = {
    enable = mkBoolOpt false "Whether to enable Swappy in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ swappy ];

    spirenix.user.home.configFile."swappy/config".source = ./config;
    spirenix.user.home.file."Pictures/screenshots/.keep".text = "";
  };
}
