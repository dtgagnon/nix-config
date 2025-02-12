{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.self-host;
in
{
  options.${namespace}.suites.self-host = {
    enable = mkBoolOpt false "Enable the self-hosted suite.";
  };

  config = mkIf cfg.enable {
    spirenix = {
      apps.qbittorrent = enabled;
      services = {
        immich = enabled;
        media = {
          audiobookshelf = enabled;
          jellyfin = enabled;
          # jellyseerr = enabled;
        };
        qbittorrent = enabled;
      };
      suites.arr = enabled;
    };
  };
}
