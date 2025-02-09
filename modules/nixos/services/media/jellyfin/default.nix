{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkMerge mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.media.jellyfin;
in
{
  options.${namespace}.services.media.jellyfin = {
    enable = mkBoolOpt false "Enable Jellyfin service";
    dataDir = mkOpt types.path "/srv/apps/jellyfin" "Data directory for Jellyfin";

    jellyseerr = mkBoolOpt false "Enable Jellyseerr media request manager and coordinator";
  };

  config = mkMerge [
    mkIf cfg.enable {
      services.jellyfin = {
        enable = true;
        user = "jellyfin";
        group = "jellyfin";
        inherit (cfg) dataDir;
      };

      environment.systemPackages = with pkgs; [
        jellyfin
        jellyfin-web
        jellyfin-ffmpeg
      ];

      users.groups.jellyfin = { };

      #caddy reverse-proxy for jellyfin here something like spirenix.services.caddy.<option (port, origin, etc).
    }
    mkIf cfg.jellyseerr {
      services.jellyseer = {
        enable = true;
        package = pkgs.jellyseer;
        configDir = "/srv/apps/jellyseerr/config";
        port = 5055;
        openFirewall = false;
      };
    }
  ];
}
