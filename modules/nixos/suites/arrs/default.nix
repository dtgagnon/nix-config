{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.arrs;
in
{
  options.${namespace}.suites.arrs = {
    enable = mkBoolOpt false "Enable the arr suite configuration";
  };

  config = mkIf cfg.enable {
    spirenix.services.arrs = {
      enable = true;
      bazarr = enabled;
      jellyfin = enabled;
      jellyseerr = enabled;
      lidarr = enabled;
      prowlarr = enabled;
      qbittorrent = enabled;
      radarr = enabled;
      readarr = enabled;
      sabnzbd = enabled;
      sonarr = {
        enable = true;
        enableAnimeServer = true;
      };
    };
  };
}
