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
    ;

  cfg = config.${namespace}.security.crowdsec;

  # Whitelist parser for s02-enrich stage
  whitelistParser = {
    name = "spirenix/whitelist";
    description = "Whitelist trusted networks and IPs";
    whitelist = {
      reason = "Trusted network/IP";
      ip = cfg.whitelistedIps;
      cidr = cfg.whitelistedCidrs;
    };
  };

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
    # Create static crowdsec user/group (required for persistence with impermanence)
    users.users.crowdsec = {
      isSystemUser = true;
      group = "crowdsec";
      home = "/var/lib/crowdsec";
    };
    users.groups.crowdsec = { };

    # Ensure directories exist with correct permissions
    systemd.tmpfiles.rules = [
      "d /var/log/traefik 0755 root root -"
      "d /var/lib/crowdsec 0750 crowdsec crowdsec -"
    ];

    # Override to use static user instead of DynamicUser (required for persistence)
    systemd.services.crowdsec.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "crowdsec";
      Group = "crowdsec";
    };

    systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "crowdsec";
      Group = "crowdsec";
    };

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

        # Whitelist parser to exclude trusted IPs/CIDRs from detection
        parsers.s02Enrich = [ whitelistParser ];
      };

      # API settings (general maps to CrowdSec's config.yaml)
      settings = {
        # Credentials file for the agent to authenticate with the local API
        lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";

        general.api.server = {
          enable = true; # Required for local bouncer registration
          listen_uri = "127.0.0.1:8080";
        };
      };
    };

    # Ensure crowdsec service waits for network and clean up stale parser symlinks
    # HACK: The nixpkgs crowdsec module creates tmpfiles symlinks with hash-based filenames
    # (e.g., abc123-parsers-s02-enrich.yaml). When config content changes, new symlinks are
    # created with different hashes, but old ones aren't cleaned up. CrowdSec loads all yaml
    # files and fails on stale ones. This workaround wipes and recreates symlinks on each start.
    # TODO: Check if this is fixed upstream in nixpkgs and remove this workaround.
    # Suspected bug: services.crowdsec tmpfiles should use fixed filenames or clean up old ones.
    systemd.services.crowdsec = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig.ExecStartPre = lib.mkBefore [
        "+${pkgs.writeShellScript "crowdsec-cleanup-stale-parsers" ''
          # Remove all yaml symlinks from config directories (stale ones accumulate)
          for dir in /etc/crowdsec/parsers/s00-raw \
                     /etc/crowdsec/parsers/s01-parse \
                     /etc/crowdsec/parsers/s02-enrich \
                     /etc/crowdsec/postoverflows/s01-whitelist \
                     /etc/crowdsec/scenarios \
                     /etc/crowdsec/contexts \
                     /etc/crowdsec/notifications; do
            if [ -d "$dir" ]; then
              find "$dir" -maxdepth 1 -name "*.yaml" -type l -delete 2>/dev/null || true
            fi
          done
          # Recreate current symlinks via tmpfiles
          systemd-tmpfiles --create --prefix=/etc/crowdsec
        ''}"
      ];
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
      {
        directory = "/var/lib/crowdsec";
        user = "crowdsec";
        group = "crowdsec";
        mode = "0750";
      }
      "/var/log/traefik"
    ];
  };
}
