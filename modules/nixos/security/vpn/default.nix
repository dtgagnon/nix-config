{ 
  lib,
  pkgs,
  config,
  namespace, 
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.security.vpn;
in {
  options.${namespace}.security.vpn = {
    enable = mkBoolOpt false "Enable VPN";
    provider = mkOpt (types.strOfEnum ["proton-vpn", "tailscale"]) "proton-vpn" "VPN provider";
  };

  config = mkIf cfg.enable && cfg.provider == "proton-vpn" {
    environment.systemPackages = [ pkgs.protonvpn-gui ];
  };
}