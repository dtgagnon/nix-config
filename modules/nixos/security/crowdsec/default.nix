{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    concatStringsSep
    ;

  cfg = config.${namespace}.security.crowdsec;

  # Build the whitelist YAML for the custom parser
  whitelistYaml = pkgs.writeText "whitelist.yaml" ''
    name: spirenix/whitelist
    description: "Whitelist trusted networks and IPs"
    whitelist:
      reason: "Trusted network/IP"
      ip:
        ${concatStringsSep "\n        " (map (ip: "- \"${ip}\"") cfg.whitelistedIps)}
      cidr:
        ${concatStringsSep "\n        " (map (cidr: "- \"${cidr}\"") cfg.whitelistedCidrs)}
  '';

  # Default collections to install
  defaultCollections = [
    "crowdsecurity/traefik"
    "crowdsecurity/linux"
  ];

  # Build acquisitions config - file source for Traefik logs
  traefikAcquisition = {
    source = "file";
    filenames = [ cfg.traefikLogPath ];
    labels.type = "traefik";
  };

  # SSH via journalctl
  sshAcquisition = {
    source = "journalctl";
    journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
    labels.type = "syslog";
  };

  defaultAcquisitions = [
    traefikAcquisition
    sshAcquisition
  ];

  # Custom profiles with configurable ban duration
  banProfile = {
    name = "default_ip_remediation";
    filters = [ "Alert.Remediation == true && Alert.GetScope() == \"Ip\"" ];
    decisions = [
      {
        type = "ban";
        duration = cfg.banDuration;
      }
    ];
    on_success = "break";
  };
in
{
  options.${namespace}.security.crowdsec = {
    enable = mkEnableOption "CrowdSec intrusion detection with firewall bouncer";

    traefikLogPath = mkOption {
      type = types.str;
      default = "/var/log/traefik/access.log";
      description = "Path to Traefik access log for CrowdSec to monitor";
    };

    banDuration = mkOption {
      type = types.str;
      default = "4h";
      description = "Duration to ban detected malicious IPs";
    };

    whitelistedCidrs = mkOption {
      type = types.listOf types.str;
      default = [ "100.64.0.0/10" ];
      description = "CIDR ranges to never ban (default includes Tailscale CGNAT range)";
    };

    whitelistedIps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Individual IPs to never ban";
    };

    enableCapi = mkOption {
      type = types.bool;
      default = true;
      description = "Enable CrowdSec Central API for community blocklists";
    };

    extraCollections = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional CrowdSec hub collections to install";
      example = [ "crowdsecurity/nginx" ];
    };

    extraAcquisitions = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Additional log acquisition sources";
      example = [
        {
          source = "file";
          filenames = [ "/var/log/nginx/access.log" ];
          labels.type = "nginx";
        }
      ];
    };
  };

  config = mkIf cfg.enable {
    # Ensure log directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d /var/log/traefik 0755 root root -"
    ];

    # CrowdSec Local API + Agent
    services.crowdsec = {
      enable = true;

      # Hub collections for Traefik and Linux
      hub.collections = defaultCollections ++ cfg.extraCollections;

      # Local configuration
      localConfig = {
        # Log acquisition sources
        acquisitions = defaultAcquisitions ++ cfg.extraAcquisitions;

        # Custom ban profile with configurable duration
        profiles = [ banProfile ];

        # Whitelist parser for trusted networks
        parsers.s02Enrich = mkIf (cfg.whitelistedCidrs != [ ] || cfg.whitelistedIps != [ ]) [
          whitelistYaml
        ];
      };

      # API settings
      settings = {
        api.server.listen_uri = "127.0.0.1:8080";
      };
    };

    # Ensure crowdsec service waits for network
    systemd.services.crowdsec = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    # CrowdSec Firewall Bouncer (blocks at nftables level)
    services.crowdsec-firewall-bouncer = {
      enable = true;

      # Auto-register with local CrowdSec LAPI
      registerBouncer.enable = true;

      settings = {
        api_url = "http://127.0.0.1:8080";
        update_frequency = "10s";
        log_mode = "stdout";
        log_level = "info";

        # nftables configuration
        nftables = {
          ipv4 = {
            enabled = true;
            set-only = false;
            table = "crowdsec";
            chain = "crowdsec-chain";
          };
          ipv6 = {
            enabled = true;
            set-only = false;
            table = "crowdsec6";
            chain = "crowdsec6-chain";
          };
        };
      };
    };

    # Persistence for CrowdSec state
    ${namespace}.system.preservation.extraSysDirs = [
      "var/lib/crowdsec"
      "var/log/traefik"
    ];
  };
}
