{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.arrs.lidarr;
in
{
  options.${namespace}.services.arrs.lidarr = {
    enable = mkBoolOpt false "Enable Lidarr";
    openFirewall = mkOpt types.bool false "Open firewall ports for Lidarr.";
    dataDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/lidarr" "Directory for Lidarr data.";
  };

  config = mkIf cfg.enable {
    services.lidarr = {
      enable = true;
      package = pkgs.lidarr;
      user = "lidarr";
      group = "media";
      inherit (cfg) openFirewall dataDir;
    };
  };
}
