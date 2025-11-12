{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.services.openwebui;
in
{
  options.${namespace}.services.openwebui = {
    enable = mkEnableOption "Enable the Open WebUI local LLM interface";
  };

  config = mkIf cfg.enable {

    services.open-webui = {
      enable = true;
      host = "100.100.2.1";
      port = 11435;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OLLAMA_API_BASE_URL = "http://100.100.2.1:11434";
        WEBUI_AUTH = "True";
        # PostgreSQL database configuration
        DATABASE_URL = "postgresql:///openwebui?host=/run/postgresql";
      };
      # environmentFile = ""; # Useful for passing secrets to the service
    };

    systemd.services.open-webui = {
      after = [ "postgresql.service" "tailscaled.service" ];
      requires = [ "postgresql.service" "tailscaled.service" ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkForce "openwebui";
        Group = lib.mkForce "openwebui";
      };
    };

    users = {
      groups.openwebui = { };
      users.openwebui = {
        isSystemUser = true;
        group = "openwebui";
      };
    };

    # Enable PostgreSQL service
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "openwebui" ];
      ensureUsers = [
        { name = "openwebui"; ensureDBOwnership = true; ensureClauses.login = true; }
      ];
    };

  };
}
