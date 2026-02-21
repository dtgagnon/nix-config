{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.netbird;
in
{
  options.${namespace}.services.netbird = {
    enable = mkBoolOpt false "Enable NetBird VPN client";
    port = mkOpt types.port 51820 "Port the NetBird client listens on";
    openFirewall = mkBoolOpt true "Open firewall ports for peer-to-peer communication";
    useRoutingFeatures = mkBoolOpt false "Enable advanced routing (Network Resources, Routes, exit nodes)";
  };

  config = mkIf cfg.enable {
    services.netbird = {
      enable = true;
      inherit (cfg) useRoutingFeatures;
      clients.default = {
        port = cfg.port;
        openFirewall = cfg.openFirewall;
      };
    };
  };
}
