{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.media.radarr;
in
{
  options.${namespace}.services.media.radarr = {
    enable = mkBoolOpt false "Enable Radarr";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Radarr.";
    dataDir = mkOpt types.str "/srv/apps/radarr" "Directory for Radarr data";
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
