{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.n8n;
in
{
  options.${namespace}.services.n8n = {
    enable = mkBoolOpt false "Enable the n8n service";
  };

  config = mkIf cfg.enable {
    # Configure sops secret for encryption key
    sops.secrets.n8n_crypt_key = {
      owner = "n8n";
      group = "n8n";
    };

    services.n8n = {
      enable = true;
      openFirewall = false;
      environment = {
        # PostgreSQL database configuration
        DB_TYPE = "postgresdb";
        DB_POSTGRESDB_HOST = "/run/postgresql";
        DB_POSTGRESDB_DATABASE = "n8n";
        DB_POSTGRESDB_USER = "n8n";

        # Reduce graceful shutdown timeout for faster restarts
        N8N_GRACEFUL_SHUTDOWN_TIMEOUT = "10";
      };
    };

    # Configure systemd service
    systemd.services.n8n = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];

      serviceConfig = {
        # Use static user for PostgreSQL peer authentication
        DynamicUser = lib.mkForce false;
        User = lib.mkForce "n8n";
        Group = lib.mkForce "n8n";

        # Load encryption key from sops secret
        EnvironmentFile = config.sops.secrets.n8n_crypt_key.path;

        # Upstream bug: N8N_RUNNERS_AUTH_TOKEN_FILE defaults to null and
        # LoadCredential tries to interpolate it, causing "cannot coerce null
        # to a string". Safe to clear since we use EnvironmentFile for secrets.
        LoadCredential = lib.mkForce [ ];

        # Reduce systemd timeout to match n8n's internal timeout
        TimeoutStopSec = 15; # 10s n8n timeout + 5s buffer
      };
    };

    # Create static n8n user
    users = {
      groups.n8n = { };
      users.n8n = {
        isSystemUser = true;
        group = "n8n";
      };
    };

    # Enable PostgreSQL and create database
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "n8n" ];
      ensureUsers = [
        {
          name = "n8n";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };
  };
}
