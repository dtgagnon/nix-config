{
  lib,
  config,
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
  cfg = config.${namespace}.services.sparky-fitness;
in
{
  options.${namespace}.services.sparky-fitness = {
    enable = mkEnableOption "SparkyFitness - family fitness and nutrition tracker via OCI containers";

    port = mkOption {
      type = types.port;
      default = 3004;
      description = "Port to expose the SparkyFitness web frontend on the host";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/sparky-fitness";
      description = "Directory for persistent SparkyFitness data (database, backups, uploads)";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "SparkyFitness container image tag for both frontend and server images";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the SparkyFitness frontend port";
    };

    frontendUrl = mkOption {
      type = types.str;
      default = "http://localhost:${toString cfg.port}";
      description = "Public URL of the SparkyFitness frontend, used for CORS configuration";
    };

    database = {
      name = mkOption {
        type = types.str;
        default = "sparkyfitness_db";
        description = "PostgreSQL database name";
      };

      user = mkOption {
        type = types.str;
        default = "sparky";
        description = "PostgreSQL superuser for DB initialization and migrations";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to a file containing the database password. If null, uses SPARKY_FITNESS_DB_PASSWORD from environmentFile";
      };

      appUser = mkOption {
        type = types.str;
        default = "sparky_app";
        description = "PostgreSQL application user with limited privileges";
      };

      appPasswordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to a file containing the app database password. If null, uses SPARKY_FITNESS_APP_DB_PASSWORD from environmentFile";
      };
    };

    apiEncryptionKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a file containing the 64-character hex API encryption key. If null, uses SPARKY_FITNESS_API_ENCRYPTION_KEY from environmentFile";
    };

    betterAuthSecretFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a file containing the Better Auth secret. If null, uses BETTER_AUTH_SECRET from environmentFile";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to an environment file containing secrets and configuration (DB passwords, API keys, etc.)";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables passed to the SparkyFitness server container";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        sparky-fitness-db = {
          image = "postgres:15-alpine";
          autoStart = true;

          environment = {
            POSTGRES_DB = cfg.database.name;
            POSTGRES_USER = cfg.database.user;
          };

          environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;

          volumes = [
            "${cfg.dataDir}/postgresql:/var/lib/postgresql/data"
          ];

          extraOptions = [
            "--network=sparky-fitness-network"
          ];
        };

        sparky-fitness-server = {
          image = "codewithcj/sparkyfitness_server:${cfg.imageTag}";
          autoStart = true;
          dependsOn = [ "sparky-fitness-db" ];

          environment = {
            SPARKY_FITNESS_DB_USER = cfg.database.user;
            SPARKY_FITNESS_DB_HOST = "sparky-fitness-db";
            SPARKY_FITNESS_DB_NAME = cfg.database.name;
            SPARKY_FITNESS_DB_PORT = "5432";
            SPARKY_FITNESS_APP_DB_USER = cfg.database.appUser;
            SPARKY_FITNESS_FRONTEND_URL = cfg.frontendUrl;
            SPARKY_FITNESS_LOG_LEVEL = "ERROR";
          } // cfg.extraEnvironment;

          environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;

          volumes = [
            "${cfg.dataDir}/backup:/app/SparkyFitnessServer/backup"
            "${cfg.dataDir}/uploads:/app/SparkyFitnessServer/uploads"
          ];

          extraOptions = [
            "--network=sparky-fitness-network"
          ];
        };

        sparky-fitness-frontend = {
          image = "codewithcj/sparkyfitness:${cfg.imageTag}";
          autoStart = true;
          dependsOn = [ "sparky-fitness-server" ];

          ports = [
            "${toString cfg.port}:80"
          ];

          environment = {
            SPARKY_FITNESS_FRONTEND_URL = cfg.frontendUrl;
            SPARKY_FITNESS_SERVER_HOST = "sparky-fitness-server";
            SPARKY_FITNESS_SERVER_PORT = "3010";
          };

          extraOptions = [
            "--network=sparky-fitness-network"
          ];
        };
      };
    };

    # Ensure podman runtime is available
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Create the shared podman network
    systemd.services.sparky-fitness-network = {
      description = "Create podman network for SparkyFitness";
      after = [ "podman.service" ];
      wantedBy = [
        "podman-sparky-fitness-db.service"
        "podman-sparky-fitness-server.service"
        "podman-sparky-fitness-frontend.service"
      ];
      before = [
        "podman-sparky-fitness-db.service"
        "podman-sparky-fitness-server.service"
        "podman-sparky-fitness-frontend.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.virtualisation.podman.package}/bin/podman network create sparky-fitness-network --ignore";
        ExecStop = "${config.virtualisation.podman.package}/bin/podman network rm sparky-fitness-network --force";
      };
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0755 root root - -"
      "d '${cfg.dataDir}/postgresql' 0755 root root - -"
      "d '${cfg.dataDir}/backup' 0755 root root - -"
      "d '${cfg.dataDir}/uploads' 0755 root root - -"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    ${namespace}.system.preservation.extraSysDirs = [
      cfg.dataDir
    ];
  };
}
