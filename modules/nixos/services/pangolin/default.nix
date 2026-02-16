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
    mkMerge
    types
    ;
  cfg = config.${namespace}.services.pangolin;
  crowdsecCfg = config.${namespace}.security.crowdsec;

  # MaxMind GeoLite2 database paths
  geoDbDir = "/var/lib/pangolin-geolite2";
  geoCountryPath = "${geoDbDir}/GeoLite2-Country.mmdb";
  geoAsnPath = "${geoDbDir}/GeoLite2-ASN.mmdb";
  geoCountryEtag = "${geoDbDir}/country.etag";
  geoAsnEtag = "${geoDbDir}/asn.etag";

  # P3TERX/GeoLite.mmdb - actively maintained redistribution with raw .mmdb files
  # Updated daily, provides direct downloads without needing MaxMind license key
  geoCountryUrl = "https://raw.githubusercontent.com/P3TERX/GeoLite.mmdb/download/GeoLite2-Country.mmdb";
  geoAsnUrl = "https://raw.githubusercontent.com/P3TERX/GeoLite.mmdb/download/GeoLite2-ASN.mmdb";

  # Update script that only downloads if ETag changed
  updateScript = pkgs.writeShellScript "update-geolite2" ''
    set -euo pipefail

    mkdir -p "${geoDbDir}"
    cd "${geoDbDir}"

    download_if_changed() {
      local url="$1"
      local dest="$2"
      local etag_file="$3"
      local name="$4"

      TMPFILE=$(mktemp)
      HTTP_CODE=$(${pkgs.curl}/bin/curl -sSL \
        --etag-compare "$etag_file" \
        --etag-save "$etag_file.new" \
        -o "$TMPFILE" \
        -w "%{http_code}" \
        "$url")

      if [ "$HTTP_CODE" = "200" ]; then
        mv "$TMPFILE" "$dest"
        mv "$etag_file.new" "$etag_file"
        chown pangolin:pangolin "$dest"
        chmod 0644 "$dest"
        echo "$name updated"
      elif [ "$HTTP_CODE" = "304" ]; then
        rm -f "$TMPFILE" "$etag_file.new"
        echo "$name is up-to-date"
      else
        rm -f "$TMPFILE" "$etag_file.new"
        echo "Failed to check $name: HTTP $HTTP_CODE" >&2
        return 1
      fi
    }

    download_if_changed "${geoCountryUrl}" "${geoCountryPath}" "${geoCountryEtag}" "GeoLite2-Country"
    download_if_changed "${geoAsnUrl}" "${geoAsnPath}" "${geoAsnEtag}" "GeoLite2-ASN"
  '';
in
{
  options.${namespace}.services.pangolin = {
    enable = mkEnableOption "Pangolin tunneled reverse proxy with identity and access management";

    baseDomain = mkOption {
      type = types.str;
      description = "Base domain for Pangolin (e.g., 'example.com'). Services will be subdomains of this.";
      example = "example.com";
    };

    geoBlocking = {
      enable = mkEnableOption "geo-blocking support using MaxMind GeoLite2 database";

      updateInterval = mkOption {
        type = types.str;
        default = "weekly";
        description = "How often to check for GeoLite2 database updates (systemd calendar format)";
        example = "daily";
      };
    };

    extraCorsOrigins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional origins to allow for CORS (e.g., Tailnet IPs for direct access)";
      example = [ "http://100.100.90.1:3002" ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Base Pangolin configuration
    {
      # Override upstream's fossorial group with pangolin
      users.users.pangolin.group = lib.mkForce "pangolin";
      users.groups.pangolin = { };

      # Sops secrets:
      #   pangolin/env: SERVER_SECRET (min 32 chars), optionally CF_DNS_API_TOKEN, EMAIL_SMTP_PASS
      #   pangolin/acme-email: Email address for Let's Encrypt registration
      sops.secrets."pangolin/env" = {
        owner = "pangolin";
        group = "pangolin";
        mode = "0400";
      };

      sops.secrets."pangolin/acme-email" = { };

      services.pangolin = {
        enable = true;
        baseDomain = cfg.baseDomain;
        dashboardDomain = "pangolin.${cfg.baseDomain}";
        # Use sops placeholder - will be substituted in the template
        letsEncryptEmail = config.sops.placeholder."pangolin/acme-email";
        openFirewall = true;
        environmentFile = config.sops.secrets."pangolin/env".path;
      };

      # Set the dynamic config directory required by the new traefik module
      # (dynamic.files requires dynamic.dir to be set for the file provider)
      services.traefik.dynamic.dir = "/var/lib/traefik/dynamic";

      # Use sops template for static config with ACME email secret
      sops.templates."traefik-config.json" = {
        content = builtins.toJSON config.services.traefik.static.settings;
        owner = "root";
        group = "root";
        mode = "0644";
      };

      # Override Traefik to use the sops-rendered JSON config
      systemd.services.traefik = {
        after = [ "sops-nix.service" ];
        serviceConfig.ExecStart = lib.mkForce "${pkgs.traefik}/bin/traefik --configfile=${
          config.sops.templates."traefik-config.json".path
        }";
      };

      # Base security and feature configuration
      services.pangolin.settings = {
        app = {
          log_level = "info";
          save_logs = true;
          log_failed_attempts = true;
          telemetry = {
            anonymous_usage = false;
          };
          notifications = {
            product_updates = false;
            new_releases = true;
          };
        };

        server = {
          # Session lengths (in hours)
          dashboard_session_length_hours = 168; # 7 days
          resource_session_length_hours = 168;
          # Trust proxy headers (1 = trust first proxy)
          trust_proxy = 1;
          # CORS configuration
          cors = {
            origins = [ "https://pangolin.${cfg.baseDomain}" ] ++ cfg.extraCorsOrigins;
            methods = [
              "GET"
              "POST"
              "PUT"
              "DELETE"
              "PATCH"
            ];
            allowed_headers = [
              "X-CSRF-Token"
              "Content-Type"
            ];
            credentials = true;
          };
          # MaxMind databases for geo/ASN blocking (when enabled)
          maxmind_db_path = mkIf cfg.geoBlocking.enable geoCountryPath;
          maxmind_asn_path = mkIf cfg.geoBlocking.enable geoAsnPath;
        };

        rate_limits = {
          global = {
            window_minutes = 1;
            max_requests = 80;
          };
          auth = {
            window_minutes = 5;
            max_requests = 5;
          };
        };

        # Traefik integration
        traefik = {
          cert_resolver = "letsencrypt";
          prefer_wildcard_cert = false;
          allow_raw_resources = true;
        };

        flags = {
          require_email_verification = false;
          disable_signup_without_invite = true;
          disable_user_create_org = true;
          allow_raw_resources = true;
          # Must be true - nixpkgs bug creates api.${baseDomain} routers even when false
          enable_integration_api = true;
          disable_local_sites = false;
          disable_basic_wireguard_sites = true; # Using Tailscale instead
          disable_product_help_banners = true;
        };
      };

      # GeoLite2 database update service
      systemd.services.pangolin-geolite2-update = mkIf cfg.geoBlocking.enable {
        description = "Update GeoLite2 Country database for Pangolin geo-blocking";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = updateScript;
          # Retry on failure with backoff
          Restart = "on-failure";
          RestartSec = "30s";
        };
      };

      # Timer for periodic updates
      systemd.timers.pangolin-geolite2-update = mkIf cfg.geoBlocking.enable {
        description = "Periodic GeoLite2 database update for Pangolin";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.geoBlocking.updateInterval;
          Persistent = true; # Run immediately if missed while system was off
          RandomizedDelaySec = "1h"; # Spread load on upstream server
        };
      };

      # Ensure database exists before Pangolin starts + fix .next permissions
      systemd.services.pangolin = {
        after = mkIf cfg.geoBlocking.enable [ "pangolin-geolite2-update.service" ];
        wants = mkIf cfg.geoBlocking.enable [ "pangolin-geolite2-update.service" ];
        # HACK: Upstream pangolin module copies .next from nix store with read-only permissions,
        # but Next.js needs to write to .next/cache at runtime. Fix permissions on each start.
        # TODO: Check if fixed upstream in nixpkgs and remove this workaround.
        serviceConfig.ExecStartPre = lib.mkAfter [
          "+${pkgs.writeShellScript "pangolin-fix-next-perms" ''
            if [ -d /var/lib/pangolin/.next ]; then
              chmod -R u+w /var/lib/pangolin/.next
            fi
          ''}"
        ];
      };
    }

    # CrowdSec integration: enable Traefik access logging for intrusion detection
    (mkIf crowdsecCfg.enable {
      # Enable Traefik access logging for CrowdSec to parse
      services.traefik.static.settings.accessLog = {
        filePath = crowdsecCfg.traefikLogPath;
        format = "json";
        bufferingSize = 100;
      };

      # Ensure Traefik starts after the firewall bouncer is ready
      systemd.services.traefik = {
        after = [ "crowdsec-firewall-bouncer.service" ];
        wants = [ "crowdsec-firewall-bouncer.service" ];
      };
    })
  ]);
}
