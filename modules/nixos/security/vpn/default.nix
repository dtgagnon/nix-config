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
    peerPublicKey = mkOption {
      type = types.str;
      description = "ProtonVPN WireGuard peer public key (base64, non-secret).";
      example = "u3y1m4Qn3c+q0...==";
      default = "ntBhUr1CJmbVydw6cgccMFGSzEcPugiikF/l4NuDygA=";
    };
    endpoint = mkOption {
      type = types.str;
      default = "node-us-304.protonvpn.net:51820";
      description = "ProtonVPN WireGuard endpoint (host:port).";
    };
    vpnRouteTable = mkOption {
      type = types.str;
      default = "52830";
      description = "Routing table ID used for ProtonVPN full-tunnel policy routing.";
    };
    wgFirewallMark = mkOption {
      type = types.int;
      default = 256; # 0x100
      description = "Fwmark set on packets originating from wg-proton itself.";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.provider == "proton-vpn") {
      environment.systemPackages = [
        pkgs.protonvpn-gui
      ];
    })

    (mkIf (cfg.provider == "proton-vpn" && cfg.tailscaleCompat) {

      systemd.network = {
        enable = true;
        networks = {
          "10-wired" = {
            matchConfig.Name = "enp3s0";
            networkConfig.DHCP = "yes";
            domains = [ "~protonvpn.net" ]; #NOTE Followup on this, I don't understand how it works.
          };
          "30-wg-proton" = {
            matchConfig.Name = "wg-proton";
            address = [ "10.2.0.2/32" "2a07:b944::2:2/128" ];
            # Proton's internal DNS - used once VPN is up
            dns = [ "10.2.0.1" "2a07:b944::2:1" ];
            # Make this link the default DNS route when up
            domains = [ "~." ];
            networkConfig = {
              ConfigureWithoutCarrier = true; # Configure the interface even before "carrier"
              DNSDefaultRoute = true;
            };

            # Install default routes into our custom table for v4 and v6
            routes = [
              { Destination = "0.0.0.0/0"; Table = cfg.vpnRouteTable; }
              { Destination = "::/0"; Table = cfg.vpnRouteTable; }
            ];

            # Policy routing:
            #  - Keep LAN subnets direct (main table)
            #  - Send everything else to table 52830
            #  - EXCEPT packets marked by WireGuard itself (FirewallMark=0x100) —
            #    those are the tunnel's own handshake packets and must use main.
            routingPolicyRules = [
              # Local IPv4 LANs stay outside the VPN
              { To = "192.168.50.0/24"; Table = "main"; Priority = 100; }
              { To = "192.168.51.0/24"; Table = "main"; Priority = 110; }
              # Local IPv6 ULA (adjust to actual prefix as needed)
              { Family = "ipv6"; To = "fd33:62a6:8e4:b346::/64"; Table = "main"; Priority = 120; }

              # All other traffic -> VPN table, but not WG's own marked packets
              { FirewallMark = cfg.wgFirewallMark; InvertRule = true; Table = cfg.vpnRouteTable; Priority = 32765; }
              { Family = "ipv6"; FirewallMark = cfg.wgFirewallMark; InvertRule = true; Table = cfg.vpnRouteTable; Priority = 32765; }
            ];
          };
        };
        netdevs = {
          "30-wg-proton" = {
            netdevConfig = {
              Name = "wg-proton";
              Kind = "wireguard";
            };
            wireguardConfig = {
              PrivateKeyFile = config.sops.secrets."pvpn/priKey".path;
              FirewallMark = cfg.wgFirewallMark;
            };
            wireguardPeers = [
              {
                PublicKey = cfg.peerPublicKey;
                AllowedIPs = [ "0.0.0.0/0" "::/0" ];
                Endpoint = cfg.endpoint;
                PersistentKeepalive = 25;
              }
            ];
          };
        };
      };

      # Let systemd-networkd manage DHCP, not legacy networking
      networking.useDHCP = false;

      # DNS manager
      services.resolved.enable = true;

      # Tailscale: let it run normally, but don't let it own DNS
      services.tailscale.extraUpFlags = [ "--accept-dns=false" ];

      # Attach MagicDNS for tailscale-only names (w/o owning global DNS)
      systemd.services.tailscale-splitdns = {
        description = "Attach MagicDNS to tailscale0 (systemd-resolved split DNS)";
        after = [ "tailscaled.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        partOf = [ "tailscaled.service" ];
        path = [ pkgs.systemd ];
        script = ''
          # Route *.ts.net via MagicDNS on the tailnet
          resolvectl dns tailscale0 100.100.100.100
          resolvectl domain tailscale0 "~.aegean-interval.ts.net"
        '';
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
        };
      };

      sops.secrets = {
        "pvpn/priKey" = { };
        "pvpn/presharedKey" = { };
        "pvpn/pubKey" = { };
      };
    })
  ];
}
