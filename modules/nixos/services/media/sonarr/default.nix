{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.media.sonarr;
in
{
  options.${namespace}.services.media.sonarr = {
    enable = mkBoolOpt false "Enable Sonarr";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Sonarr.";
    dataDir = mkOpt types.str "/srv/apps/sonarr" "Directory for Sonarr data";
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
