{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.keyring;
in
{
  options.${namespace}.desktop.addons.keyring = {
    enable = mkBoolOpt false "Whether to enable the gnome keyring.";
  };

  config = mkIf cfg.enable {
    programs.seahorse.enable = true;

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}