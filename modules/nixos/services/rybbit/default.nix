{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.${namespace}.services.rybbit;

  # GeoLite2 database for IP geolocation
  geoDbDir = "/var/lib/rybbit-geolite2";
  geoCityPath = "${geoDbDir}/GeoLite2-City.mmdb";
  geoCityEtag = "${geoDbDir}/city.etag";
  geoCityUrl = "https://raw.githubusercontent.com/P3TERX/GeoLite.mmdb/download/GeoLite2-City.mmdb";

  updateScript = pkgs.writeShellScript "update-rybbit-geolite2" ''
    set -euo pipefail

    mkdir -p "${geoDbDir}"
    cd "${geoDbDir}"

    TMPFILE=$(mktemp)
    HTTP_CODE=$(${pkgs.curl}/bin/curl -sSL \
      --etag-compare "${geoCityEtag}" \
      --etag-save "${geoCityEtag}.new" \
      -o "$TMPFILE" \
      -w "%{http_code}" \
      "${geoCityUrl}")

    if [ "$HTTP_CODE" = "200" ]; then
      mv "$TMPFILE" "${geoCityPath}"
      mv "${geoCityEtag}.new" "${geoCityEtag}"
      chown rybbit:rybbit "${geoCityPath}"
      chmod 0644 "${geoCityPath}"
      echo "GeoLite2-City updated"
    elif [ "$HTTP_CODE" = "304" ]; then
      rm -f "$TMPFILE" "${geoCityEtag}.new"
      echo "GeoLite2-City is up-to-date"
    else
      rm -f "$TMPFILE" "${geoCityEtag}.new"
      echo "Failed to check GeoLite2-City: HTTP $HTTP_CODE" >&2
      return 1
    fi

    # Symlink into rybbit data dir so server finds it at process.cwd()
    ln -sf "${geoCityPath}" /var/lib/rybbit/GeoLite2-City.mmdb
  '';
in
{
  options.${namespace}.services.rybbit = {
    enable = mkEnableOption "Rybbit privacy-focused analytics platform";

    useBuiltinProxy = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Use Rybbit's built-in nginx reverse proxy.
        Set to false when using an external proxy like Pangolin.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Persistence for rybbit databases
    ${namespace}.system.preservation.extraSysDirs = [
      "/var/lib/rybbit"
      "/var/lib/rybbit-geolite2"
      "/var/lib/clickhouse"
      "/var/lib/postgresql"
    ];

    # Sops secret containing env vars for Rybbit
    # Required: BETTER_AUTH_SECRET=<random-string>
    # Optional: CLICKHOUSE_PASSWORD, POSTGRES_PASSWORD, MAPBOX_TOKEN
    sops.secrets.rybbit-env = {
      owner = "rybbit";
      group = "rybbit";
      mode = "0400";
    };

    # GeoLite2-City database update service
    systemd.services.rybbit-geolite2-update = {
      description = "Update GeoLite2 City database for Rybbit geolocation";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = updateScript;
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

    systemd.timers.rybbit-geolite2-update = {
      description = "Periodic GeoLite2-City database update for Rybbit";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    # Enable upstream module with sops secret and sensible defaults
    services.rybbit = {
      enable = true;
      secretsFile = config.sops.secrets.rybbit-env.path;

      # Server/client defaults - bind locally, let proxy handle external access
      server.port = 3001;
      server.host = "127.0.0.1";
      client.port = 3002;
      client.host = if cfg.useBuiltinProxy then "0.0.0.0" else "127.0.0.1";

      # Enable local databases by default
      clickhouse.enable = true;
      postgres.enable = true;

      # Reverse proxy - disable when using external proxy (e.g., Pangolin)
      nginx.enable = cfg.useBuiltinProxy;

      # Privacy defaults
      settings.disableSignup = true;
      settings.disableTelemetry = true;
    };

    # Ensure geo database is downloaded before rybbit-server starts
    systemd.services.rybbit-server = {
      after = [ "rybbit-geolite2-update.service" ];
      wants = [ "rybbit-geolite2-update.service" ];
    };
  };
}
