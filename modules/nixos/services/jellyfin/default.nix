{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.jellyfin;
in
{
  options.${namespace}.services.jellyfin = {
    enable = mkBoolOpt false "Enable Jellyfin service";
    dataDir = mkOpt types.path "/var/lib/jellyfin" "Data directory for Jellyfin";
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      inherit (cfg) dataDir user group;
    };

    users.users."jellyfin" = {
      isSystemUser = true;
      group = "jellyfin";
    };

    users.groups."jellyfin" = { };
  };
}
