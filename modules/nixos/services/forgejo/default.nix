{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.${namespace}.services.forgejo;
in
{
  options.${namespace}.services.forgejo = {
    enable = mkEnableOption "Forgejo self-hosted Git service";

    domain = mkOption {
      type = types.str;
      example = "git.spirenet.link";
      description = "Public domain name for the Forgejo instance (used for ROOT_URL and SSH_DOMAIN).";
    };
  };

  config = mkIf cfg.enable {
    # Persistence for Forgejo data
    ${namespace}.system.preservation.extraSysDirs = [
      "/var/lib/forgejo"
    ];

    # Sops secret for Forgejo DB password.
    # NOTE: When using PostgreSQL peer auth (createDatabase = true, socket = /run/postgresql),
    # a passwordFile is NOT required — Forgejo connects via Unix socket as the forgejo system
    # user which is granted ownership of the forgejo DB by the NixOS PostgreSQL ensureUsers
    # mechanism. The secret below is declared as a placeholder for future use or if you switch
    # to TCP-based auth.
    #TODO: add forgejo-db-password to sops secrets file if switching away from peer auth
    sops.secrets.forgejo-db-password = { };

    services.forgejo = {
      enable = true;

      database = {
        # Uses "postgres" (not "postgresql") per the forgejo module's enum.
        # With createDatabase = true (the default), the module provisions the
        # forgejo DB/user in PostgreSQL and sets socket = "/run/postgresql" so
        # that peer auth is used — no password required.
        type = "postgres";
        # createDatabase defaults to true; leave it at the default so the module
        # wires up ensureDatabases/ensureUsers against the existing PostgreSQL instance.
      };

      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}";
          # Bind locally — Pangolin handles external TLS termination
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 3000;
          SSH_DOMAIN = cfg.domain;
          START_SSH_SERVER = true;
          # Internal SSH port; adjust firewall/Pangolin routing for external port 22 if needed
          SSH_PORT = 2222;
        };

        service = {
          # No public self-registration
          DISABLE_REGISTRATION = true;
        };
      };
    };

    # Open the internal SSH port in the firewall.
    # HTTP port 3000 is intentionally left local (Pangolin proxies it).
    networking.firewall.allowedTCPPorts = [ 2222 ];
  };
}
