{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types mkMerge;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.arrs.sonarr;
in
{
  options.${namespace}.services.arrs.sonarr = {
    enable = mkBoolOpt false "Enable Sonarr";
    package = mkOpt types.package pkgs.sonarr "The specific package to default to for the sonarr service";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Sonarr.";
    dataDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/sonarr" "Directory for Sonarr data";
    enableAnimeServer = mkBoolOpt false "Enable a separate Sonarr instance for handling anime";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.sonarr = {
        enable = true;
        user = "sonarr";
        group = "media";
        inherit (cfg)
          package
          openFirewall
          dataDir
          ;
      };
    })
    (mkIf cfg.enableAnimeServer {
      systemd = {
        tmpfiles.rules = [ "d '${cfg.dataDir}-anime' 0700 sonarr media - -" ];
        services.sonarr-anime = {
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            User = "sonarr";
            Group = "media";
            ExecStart = "${cfg.package}/bin/Sonarr -nobrowser -data='${cfg.dataDir}-anime'";
            Restart = "on-failure";
          };
        };
      };
      networking.firewall = mkIf cfg.openFirewall {
        allowedTCPPorts = [ 8990 ];
      };
    })
  ];
}
