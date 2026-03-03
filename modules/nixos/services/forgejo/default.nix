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

  config = mkIf cfg.enable rec {
    # Persistence for Forgejo data
    ${namespace}.system.preservation.extraSysDirs = [
      { directory = "/var/lib/forgejo"; user = "forgejo"; group = "forgejo"; mode = "0750"; }
    ];

    # Sops secret for Forgejo DB password.
    #NOTE: When using PostgreSQL peer auth (createDatabase = true, socket = /run/postgresql), add forgejo-db-password to sops secrets file if switching away from peer auth
    # sops.secrets.forgejo-db-password = { };

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
          HTTP_PORT = 3055;
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
