{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.arrs.radarr;
in
{
  options.${namespace}.services.arrs.radarr = {
    enable = mkBoolOpt false "Enable Radarr";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Radarr.";
    dataDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/radarr" "Directory for Radarr data";
  };

  config = mkIf cfg.enable {
    services.radarr = {
      enable = true;
      package = pkgs.radarr;
      user = "radarr";
      group = "media";
      inherit (cfg)
        openFirewall
        dataDir;
    };
  };
}
