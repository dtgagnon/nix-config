{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.syncthing;
  username = config.${namespace}.user.name;
in
{
  options.${namespace}.services.syncthing = {
    enable = mkBoolOpt false "Enable Syncthing service";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = "${username}";
      dataDir = "/home/${username}";
      configDir = "/home/${username}/.config/syncthing";
    };

    # Add syncthing system configuration to persist
    ${namespace}.system.impermanence.extraHomeDirs = [
      ".config/syncthing"
      ".local/state/syncthing"
    ];
  };
}