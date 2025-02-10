{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  media = config.${namespace}.services.media;
in
{
  config = mkIf (media.audiobookshelf.enable || media.bazarr.enable || media.jellyfin.enable || media.lidarr.enable || media.prowlarr.enable || media.radarr.enable || media.readarr.enable || media.sonarr.enable) {
    config.users.groups.media = { };
  };
}
