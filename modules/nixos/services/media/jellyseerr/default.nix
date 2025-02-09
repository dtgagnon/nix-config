{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.media.jellyseerr;
in
{
  options.${namespace}.services.media.jellyseerr = {
    enable = mkBoolOpt false "Enable Jellyseerr service";
    port = mkOpt types.int 5055 "Port for Jellyseerr";
    configDir = mkOpt types.str "/srv/apps/jellyseerr/config" "Config directory for Jellyseerr";
  };

  config = mkIf cfg.enable {
    services.jellyseerr = {
      enable = true;
      package = pkgs.jellyseerr;

      inherit (cfg) port configDir;

      openFirewall = false;
    };
  };
}
