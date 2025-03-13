{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.arrs.sonarr;
in
{
  options.${namespace}.services.arrs.sonarr = {
    enable = mkBoolOpt false "Enable Sonarr";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Sonarr.";
    dataDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/sonarr" "Directory for Sonarr data";
  };

  config = mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      package = pkgs.sonarr;
      user = "sonarr";
      group = "media";
      inherit (cfg)
        openFirewall
        dataDir
        ;
    };
  };
}
