{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.media.bazarr;
in
{
  options.${namespace}.services.media.bazarr = {
    enable = mkBoolOpt false "Enable Bazarr";
    port = mkOpt types.int 6767 "Port to run Bazarr on";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Bazarr.";
  };

  config = mkIf cfg.enable {
    services.bazarr = {
      enable = true;
      package = pkgs.bazarr;
      user = "bazarr";
      group = "bazarr";
      listenPort = cfg.port;
      inherit (cfg) openFirewall;
    };
  };
}
