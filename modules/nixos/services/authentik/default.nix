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
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.authentik;
in
{
  options.${namespace}.services.authentik = {
    enable = mkEnableOption "Authentik identity provider";

    version = mkOption {
      type = types.str;
      default = "2024.12.3";
      description = "Authentik version tag to use";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/authentik";
      description = "Directory to store Authentik data";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind Authentik to";
    };

    port = mkOption {
      type = types.port;
      default = 9000;
      description = "HTTP port for Authentik web interface";
    };

    httpsPort = mkOption {
      type = types.port;
      default = 9443;
      description = "HTTPS port for Authentik web interface";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/authentik-env";
      description = ''
        Path to environment file containing secrets.
        Must contain at minimum:
        - AUTHENTIK_SECRET_KEY (generate with: openssl rand 60 | base64 -w 0)
        - PG_PASS (PostgreSQL password)

        Optional secrets:
        - AUTHENTIK_EMAIL__PASSWORD (SMTP password)
        - AUTHENTIK_BOOTSTRAP_PASSWORD (initial admin password)
        - AUTHENTIK_BOOTSTRAP_TOKEN (initial admin API token)
      '';
    };

    openFirewall = mkBoolOpt false "Whether to open firewall ports for Authentik";

    postgresql = {
      enable = mkBoolOpt true "Use local PostgreSQL instance";
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "PostgreSQL host";
      };
      port = mkOption {
        type = types.port;
        default = 5432;
        description = "PostgreSQL port";
      };
      database = mkOption {
        type = types.str;
        default = "authentik";
        description = "PostgreSQL database name";
      };
      user = mkOption {
        type = types.str;
        default = "authentik";
        description = "PostgreSQL user";
      };
    };

    redis = {
      enable = mkBoolOpt true "Use local Redis instance";
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "Redis host";
      };
      port = mkOption {
        type = types.port;
        default = 6379;
        description = "Redis port";
      };
    };

    email = {
      host = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "smtp.example.com";
        description = "SMTP server hostname";
      };
      port = mkOption {
        type = types.port;
        default = 587;
        description = "SMTP server port";
      };
      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "SMTP username";
      };
      from = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "authentik@example.com";
        description = "Email from address";
      };
      useTls = mkBoolOpt true "Use TLS for SMTP";
      useSsl = mkBoolOpt false "Use SSL for SMTP";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        AUTHENTIK_LOG_LEVEL = "debug";
      };
      description = "Additional environment variables for Authentik containers";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFile != null;
        message = "spirenix.services.authentik.environmentFile must be set with AUTHENTIK_SECRET_KEY and PG_PASS";
      }
    ];

    # PostgreSQL configuration
    services.postgresql = mkIf cfg.postgresql.enable {
      enable = true;
      ensureDatabases = [ cfg.postgresql.database ];
      ensureUsers = [
        {
          name = cfg.postgresql.user;
          ensureDBOwnership = true;
        }
      ];
    };

    # Redis configuration
    services.redis.servers.authentik = mkIf cfg.redis.enable {
      enable = true;
      port = cfg.redis.port;
      bind = "127.0.0.1";
    };

    # Authentik containers
    virtualisation.oci-containers = {
      backend = "docker";

      containers.authentik-server = {
        image = "ghcr.io/goauthentik/server:${cfg.version}";
        autoStart = true;
        cmd = [ "server" ];

        extraOptions = [
          "--network=host"
          "--pull=missing"
        ];

        volumes = [
          "${cfg.dataDir}/media:/media"
          "${cfg.dataDir}/templates:/templates"
        ];

        environment = mkMerge [
          {
            AUTHENTIK_REDIS__HOST = cfg.redis.host;
            AUTHENTIK_REDIS__PORT = toString cfg.redis.port;
            AUTHENTIK_POSTGRESQL__HOST = cfg.postgresql.host;
            AUTHENTIK_POSTGRESQL__PORT = toString cfg.postgresql.port;
            AUTHENTIK_POSTGRESQL__NAME = cfg.postgresql.database;
            AUTHENTIK_POSTGRESQL__USER = cfg.postgresql.user;
            AUTHENTIK_LISTEN__HTTP = "${cfg.host}:${toString cfg.port}";
            AUTHENTIK_LISTEN__HTTPS = "${cfg.host}:${toString cfg.httpsPort}";
          }
          (mkIf (cfg.email.host != null) {
            AUTHENTIK_EMAIL__HOST = cfg.email.host;
            AUTHENTIK_EMAIL__PORT = toString cfg.email.port;
            AUTHENTIK_EMAIL__USE_TLS = if cfg.email.useTls then "true" else "false";
            AUTHENTIK_EMAIL__USE_SSL = if cfg.email.useSsl then "true" else "false";
          })
          (mkIf (cfg.email.username != null) {
            AUTHENTIK_EMAIL__USERNAME = cfg.email.username;
          })
          (mkIf (cfg.email.from != null) {
            AUTHENTIK_EMAIL__FROM = cfg.email.from;
          })
          cfg.extraEnvironment
        ];

        environmentFiles = [ cfg.environmentFile ];
      };

      containers.authentik-worker = {
        image = "ghcr.io/goauthentik/server:${cfg.version}";
        autoStart = true;
        cmd = [ "worker" ];

        extraOptions = [
          "--network=host"
          "--pull=missing"
        ];

        volumes = [
          "${cfg.dataDir}/media:/media"
          "${cfg.dataDir}/templates:/templates"
          "${cfg.dataDir}/certs:/certs"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];

        environment = mkMerge [
          {
            AUTHENTIK_REDIS__HOST = cfg.redis.host;
            AUTHENTIK_REDIS__PORT = toString cfg.redis.port;
            AUTHENTIK_POSTGRESQL__HOST = cfg.postgresql.host;
            AUTHENTIK_POSTGRESQL__PORT = toString cfg.postgresql.port;
            AUTHENTIK_POSTGRESQL__NAME = cfg.postgresql.database;
            AUTHENTIK_POSTGRESQL__USER = cfg.postgresql.user;
          }
          (mkIf (cfg.email.host != null) {
            AUTHENTIK_EMAIL__HOST = cfg.email.host;
            AUTHENTIK_EMAIL__PORT = toString cfg.email.port;
            AUTHENTIK_EMAIL__USE_TLS = if cfg.email.useTls then "true" else "false";
            AUTHENTIK_EMAIL__USE_SSL = if cfg.email.useSsl then "true" else "false";
          })
          (mkIf (cfg.email.username != null) {
            AUTHENTIK_EMAIL__USERNAME = cfg.email.username;
          })
          (mkIf (cfg.email.from != null) {
            AUTHENTIK_EMAIL__FROM = cfg.email.from;
          })
          cfg.extraEnvironment
        ];

        environmentFiles = [ cfg.environmentFile ];
      };
    };

    # Enable Docker
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    # Create data directories
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 root root - -"
      "d '${cfg.dataDir}/media' 0750 root root - -"
      "d '${cfg.dataDir}/templates' 0750 root root - -"
      "d '${cfg.dataDir}/certs' 0750 root root - -"
    ];

    # Service ordering
    systemd.services.docker-authentik-server = {
      after = [
        "docker.service"
      ]
      ++ lib.optional cfg.postgresql.enable "postgresql.service"
      ++ lib.optional cfg.redis.enable "redis-authentik.service";
      requires = [
        "docker.service"
      ]
      ++ lib.optional cfg.postgresql.enable "postgresql.service"
      ++ lib.optional cfg.redis.enable "redis-authentik.service";
    };

    systemd.services.docker-authentik-worker = {
      after = [ "docker-authentik-server.service" ];
      requires = [ "docker-authentik-server.service" ];
    };

    # Firewall
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.port
        cfg.httpsPort
      ];
    };
  };
}
