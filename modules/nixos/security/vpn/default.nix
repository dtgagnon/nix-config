{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge mkOption mkEnableOption types;
  cfg = config.${namespace}.security.vpn;
in
{
  options.${namespace}.security.vpn = {
    enable = mkEnableOption "Enable VPN";
    tailscaleCompat = mkEnableOption "Activate configuration for symbiotic tailscale and wireguard VPN";
    provider = mkOption {
      type = types.str;
      default = "proton-vpn";
      description = "Select VPN provider to enable";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.provider == "proton-vpn") {
      environment.systemPackages = [
        pkgs.protonvpn-gui
        pkgs.protonvpn-cli
      ];
    })

    (mkIf cfg.enable && cfg.tailscaleCompat {
      services.tailscale.extraUpFlags = [ "--accept-dns=false" ];
      networking.wg-quick.interfaces."wg-proton" = {
        # From Proton’s WG config:
        address = [ "YOUR_PROTON_WG_IPv4/32" "YOUR_PROTON_WG_IPv6/128" ]; # omit IPv6 if Proton conf has none
        privateKeyFile = config.sops.secrets."pvpn/priKey";
        peers = [{
          publicKey = "$PVPN_PUBKEY";
          endpoint = "$PVPN_ENDPOINT"; # e.g. us-xyz.protonvpn.net:51820
          allowedIPs = [ "0.0.0.0/0" "::/0" ]; # full-tunnel over Proton
          persistentKeepalive = 25;
        }];

        # CRITICAL: keep Proton routes out of main. Use its own table, e.g. 51820.
        table = 51820;
        # We’ll add/remove the catch-all policy rule when the tunnel comes up/down.
        postUp = ''
          # Exceptions first: keep Tailscale traffic out of Proton
          ip rule add priority 100 to 100.64.0.0/10 lookup main
          ip -6 rule add priority 100 to fd7a:115c:a1e0::/48 lookup main 2>/dev/null || true

          # Tailscale control/coordination ranges (keep out of Proton)
          ip rule add priority 101 to 192.200.0.0/24 lookup main
          ip -6 rule add priority 101 to 2606:b740:49::/48 lookup main 2>/dev/null || true

          # Proton catch-all (anything not matched above goes to table 51820)
          ip rule add priority 120 lookup 51820
        '';
        postDown = ''
          ip rule del priority 120 || true
          ip -6 rule del priority 120 || true
          ip rule del priority 101 || true
          ip -6 rule del priority 101 || true
          ip rule del priority 100 || true
          ip -6 rule del priority 100 || true
        '';
      };

      sops.secrets = {
        "pvpn/priKey" = { }; #path
        "pvpn/pubKey" = { }; #string
        "pvpn/endpoint" = { }; #string
      };
    })
  ];
}
