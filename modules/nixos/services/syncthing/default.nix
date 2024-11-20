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
in
{
  options.${namespace}.services.syncthing = {
    enable = mkBoolOpt false "Enable Syncthing service";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = config.${namespace}.user.name;
      dataDir = "/home/${config.${namespace}.user.name}";
    };

    # Add syncthing-specific persistence
    ${namespace}.system.impermanence = {
      extraSysDirs = [ "/var/lib/syncthing" ];
      extraHomeDirs = [ ".config/syncthing"];
  };
}
