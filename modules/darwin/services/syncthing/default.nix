{
  lib,
  config,
  namespace,
  ...
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
      user = "dtgagnon";
      group = "users";
      openDefaultPorts = true;
    };

    # Add syncthing system configuration to user's home persistence
    # snowfallorg.users.${config.${namespace}.user.name}.home.config.${namespace}.user.home.persistHomeDirs = [
    #   ".config/syncthing"
    #   ".local/state/syncthing"
    # ];
  };
}
