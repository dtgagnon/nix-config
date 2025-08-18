{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge mkOption mkEnableOption types;
  cfg = config.${namespace}.security.vpn;

  digResult = pkgs.runCommand "proton-server-ip"
    {
      nativeBuildInputs = [ pkgs.dnsutils ];
    } "dig 9.9.9.9 +short node-us-304.protonvpn.net A node-us-304.protonvpn.net AAAA";

  protonServerIp = lib.strings.trim (builtins.head lib.strings.splitString "\n" (builtins.readFile digResult));
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
      ];
    })

    (mkIf (cfg.provider == "proton-vpn" && cfg.tailscaleCompat) {

      systemd.network = {
        enable = true;
        networks = {
          "10-wired" = {
            matchConfig.Name = "enp3s0";
            networkConfig.DHCP = "yes";
            routes = [{
              routeConfig = {
                Designation = "${protonServerIp}/32";
                Gateway = "192.168.50.1";
              };
            }];
          };
          "30-wg-proton" = {
            matchConfig.Name = "wg-proton";
            address = [ "10.2.0.2/32" "2a07:b944::2:2/128" ];
            networkConfig = {
              DNS = [ "10.2.0.1" "2a07:b944::2:1" ];
              DefaultRouteOnDevice = true;
              RouteTable = 52830;
            };
            routingPolicyRules = [
              { ruleConfig = { To = "192.168.50.0/24"; Table = "main"; Priority = 32500; }; }
              { ruleConfig = { Family = "inet6"; To = "fd33:62a6:8e4:b346::/64"; Table = "main"; Priority = 32500; }; }
              { ruleConfig = { To = "192.168.51.0/24"; Table = "main"; Priority = 32510; }; }
              { ruleConfig = { From = "0.0.0.0/0"; Table = "52830"; Priority = 32700; }; }
              { ruleConfig = { Family = "inet6"; From = "::/0"; Table = "52830"; Priority = 32700; }; }
            ];
          };
        };
        netdevs = {
          "30-wg-proton" = {
            netdevConfig = { Name = "wg-proton"; Kind = "wireguard"; };
            wireguardConfig = { PrivateKeyFile = config.sops.secrets."pvpn/priKey".path; };
            wireguardPeers = [
              {
                wireguardPeerConfig = {
                  PublicKey = builtins.readFile config.sops.secrets."pvpn/pubKey".path;
                  AllowedIPs = [ "0.0.0.0/0" "::/0" ];
                  Endpoint = "node-us-304.protonvpn.net:51820";
                  PersistentKeepalive = 25;
                };
              }
            ];
          };
        };
      };

      networking = {
        useDHCP = false; # let networkd handle DHCP
        # resolvconf.enable = false;
      };
      # environment.etc."resolv.conf".source = "/run/systemd/resolve/stub-resolv.conf";

      # Handle DNS
      services.resolved = {
        enable = true;
        extraConfig = ''
          DNS=9.9.9.9 149.112.112.112 2620:fe::fe 2620:fe::9
        '';
      };

      services.tailscale.extraUpFlags = [ "--accept-dns=false" ];
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
