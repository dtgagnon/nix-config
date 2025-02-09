{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.media.lidarr;
in {
  options.${namespace}.services.media.lidarr = {
    enable = mkBoolOpt false "Enable Lidarr";
    openFirewall = mkOpt types.bool false "Open firewall ports for Lidarr.";
    dataDir = mkOpt types.str "/srv/apps/lidarr" "Directory for Lidarr data.";
  };

  config = mkIf cfg.enable {
    services.lidarr = {
      enable = true;
      package = pkgs.lidarr;
      user = "lidarr";
      group = "lidarr";
      inherit (cfg) openFirewall dataDir;
    };
  };
}