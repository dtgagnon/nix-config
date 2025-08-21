{ lib
, config
, namespace
, pkgs
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
    users.users.openwebui = {
      isSystemUser = true;
      group = "openwebui";
    };

    users.groups.openwebui = {};

    # Enable PostgreSQL service
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      ensureDatabases = [ "openwebui" ];
      ensureUsers = [
        {
          name = "openwebui";
          ensureDBOwnership = true;
        }
      ];
      authentication = lib.mkForce ''
        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        local   openwebui       openwebui                               peer
        host    openwebui       openwebui       127.0.0.1/32            trust
        host    openwebui       openwebui       ::1/128                 trust
      '';
    };

    services.open-webui = {
      enable = true;
      host = "100.100.2.1";
      port = 11435;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "False";
        # PostgreSQL database configuration
        DATABASE_URL = "postgresql://openwebui@localhost/openwebui";
      };
      # environmentFile = ""; # Useful for passing secrets to the service
    };

    systemd.services.open-webui.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "openwebui";
      Group = lib.mkForce "openwebui";
    };
  };
}
