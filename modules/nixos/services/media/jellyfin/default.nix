{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.media.jellyfin;
in
{
  options.${namespace}.services.media.jellyfin = {
    enable = mkBoolOpt false "Enable Jellyfin service";
    dataDir = mkOpt types.path "/srv/media/jellyfin" "Data directory for Jellyfin";
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      group = "media";
      inherit (cfg) dataDir;
    };

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    users.groups.media = { };

    #caddy reverse-proxy for jellyfin here something like spirenix.services.caddy.<option (port, origin, etc).
  };
}
