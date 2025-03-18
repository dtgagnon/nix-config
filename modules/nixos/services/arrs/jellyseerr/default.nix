{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.arrs.jellyseerr;
in
{
  options.${namespace}.services.arrs.jellyseerr = {
    enable = mkBoolOpt false "Enable Jellyseerr";
    port = mkOpt types.port 5055 "The port which the Jellyseerr web UI should listen to.";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Jellyseerr.";
    # configDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/jellyseerr" "The directory where Jellyseerr stores its config data.";
    # user = mkOpt types.str "jellyseerr" "The user that Jellyseerr should run as.";
    # group = mkOpt types.str "media" "The group that Jellyseerr should run as.";
  };

  config = mkIf cfg.enable
    {
      services.jellyseerr = {
        enable = true;
        package = pkgs.jellyseerr;
        inherit (cfg)
          openFirewall
          port
          ;
      };
      # users = {
      #   users = {
      #     ${cfg.user} = {
      #       isSystemUser = true;
      #       group = cfg.group;
      #       home = cfg.configDir;
      #     };
      #   };
      #   groups.${cfg.group} = { };
      # };
    };
}
