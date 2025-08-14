{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge mkOption mkEnableOption types;
  cfg = config.${namespace}.security.vpn;

  wgProtonConf = "wg-proton.conf";
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

    (mkIf (cfg.enable && cfg.tailscaleCompat) {
      sops.templates.${wgProtonConf} = {
        owner = "root";
        group = "root";
        mode = "0400";
        content = ''
          [Interface]
          Address = 10.2.0.2/32
          PrivateKeyFile = ${config.sops.secrets."pvpn/priKey".path}
          Table = 51820
          PostUp = ip rule add priority 100 to 100.64.0.0/10 lookup main
          PostUp = ip -6 rule add priority 100 to fd7a:115c:a1e0::/48 lookup main 2>/dev/null || true
          PostUp = ip rule add priority 101 to 192.200.0.0/24 lookup main
          PostUp = ip -6 rule add priority 101 to 2606:b740:49::/48 lookup main 2>/dev/null || true
          PostUp = ip rule add priority 120 lookup 51820
          PostDown = ip rule del priority 120 || true
          PostDown = ip -6 rule del priority 120 || true
          PostDown = ip rule del priority 101 || true
          PostDown = ip -6 rule del priority 101 || true
          PostDown = ip rule del priority 100 || true
          PostDown = ip -6 rule del priority 100 || true

          [Peer]
          PublicKey = ${config.sops.placeholder."pvpn/pubKey"}
          Endpoint = ${config.sops.placeholder."pvpn/endpoint"}
          AllowedIPs = 0.0.0.0/0, ::/0
          PersistentKeepalive = 25
        '';
      };

      sops.secrets = {
        "pvpn/priKey" = { }; #path
        "pvpn/pubKey" = { }; #string
        "pvpn/endpoint" = { }; #string
      };

      networking.wg-quick.interfaces."wg-proton".configFile = config.sops.templates.${wgProtonConf}.path;
      services.tailscale.extraUpFlags = [ "--accept-dns=false" ];

      # Handle DNS
      services.resolved = {
        enable = true;
        extraConfig = ''
          DNS=9.9.9.9 149.112.112.112 2620:fe::fe 2620:fe::9
        '';
      };
      networking.resolvconf.enable = false;
      environment.etc."resolv.conf".source = "/run/systemd/resolve/stub-resolv.conf";

      systemd.services.tailscale-splitdns = {
        description = "Attach MagicDNS to tailscale0 (systemd-resolved split DNS)";
        after = [ "tailscaled.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          # Route *.ts.net via MagicDNS on the tailnet
          resolvectl dns tailscale0 100.100.100.100
          resolvectl domain tailscale0 "~ts.net"
        '';
      };

      # Kill switch
      systemd.services.pbr-baseline = {
        description = "Baseline policy rules (+unreachable) at boot";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          # Ensure idempotency
          add_rule() { ip $1 rule show | grep -q "$3" || ip $1 rule add $2; }

          # Exceptions (mirror postUp so they exist even if Proton is down)
          add_rule "" "priority 100 to 100.64.0.0/10 lookup main" "to 100.64.0.0/10"
          add_rule "-6" "priority 100 to fd7a:115c:a1e0::/48 lookup main" "fd7a:115c:a1e0::/48" || true
          add_rule "" "priority 101 to 192.200.0.0/24 lookup main" "to 192.200.0.0/24"
          add_rule "-6" "priority 101 to 2606:b740:49::/48 lookup main" "2606:b740:49::/48" || true

          # Hard stop AFTER Proton rule (priority 120) to avoid leaks:
          # (wg-quick postUp adds priority 120 when Proton is up)
          add_rule "" "priority 121 type unreachable" "priority 121"
          add_rule "-6" "priority 121 type unreachable" "priority 121" || true
        '';
      };
    })
  ];
}
