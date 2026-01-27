{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.${namespace}.services.rybbit;
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
  };
}
