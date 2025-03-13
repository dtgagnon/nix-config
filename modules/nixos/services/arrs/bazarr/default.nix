{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.arrs.bazarr;
in
{
  options.${namespace}.services.arrs.bazarr = {
    enable = mkBoolOpt false "Enable Bazarr";
    port = mkOpt types.int 6767 "Port to run Bazarr on";
    dataDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/bazarr" "Directory for Bazarr data";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Bazarr.";
  };

  config = mkIf cfg.enable {
    services.bazarr = {
      enable = true;
      package = pkgs.bazarr;
      user = "bazarr";
      group = "media";
      listenPort = cfg.port;
      inherit (cfg) openFirewall;
    };
    #TODO: Add an override to the normal module so that we can specify the dataDir
  };
}