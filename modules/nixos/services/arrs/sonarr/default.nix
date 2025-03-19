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
    package = mkOpt types.packages pkgs.sonarr "The specific package to default to for the sonarr service";
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
      services.sonarr = {
        enable = true;
        package = cfg.package;
        user = "sonarr";
        group = "media";
        dataDir = "${cfg.dataDir}-anime";
      };
      networking.firewall = mkIf cfg.openFirewall {
        allowedTCPPorts = [ 8990 ];
      };
      # systemd = {
      #   tmpfiles.rules = [ "d '${cfg.dataDir}-anime' 0700 ${cfg.user} ${cfg.group} - -" ];
      #   services.sonarr-anime = {
      #     Type = "simple";
      #     User = cfg.user;
      #     Group = cfg.group;
      #     ExecStart = utils.escapeSystemdExecArgs [
      #       (lib.getExe cfg.package)
      #       "-nobrowser"
      #       "-data=${cfg.dataDir}-anime"
      #     ];
      #     Restart = "on-failure";
      #   };
      # };
    })
  ];
}
