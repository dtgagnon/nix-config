{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.${namespace}.services.openwebui;

  # Check which LLM backend is enabled
  ollamaEnabled = config.services.ollama.enable;
  llamaCppEnabled = config.${namespace}.services.llama-cpp.enable;
  hasLLMBackend = ollamaEnabled || llamaCppEnabled;
in
{
  options.${namespace}.services.openwebui = {
    enable = mkEnableOption "Enable the Open WebUI local LLM interface";
    jupyter = {
      enable = mkEnableOption "Enable Jupyter as the code execution backend for Open WebUI";
      port = mkOption {
        type = types.port;
        default = 8888;
        description = "Port for the Jupyter server (localhost-only)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Warn if no LLM backend is configured
    assertions = [
      {
        assertion = hasLLMBackend;
        message = "Open WebUI requires either Ollama or llama.cpp to be enabled";
      }
    ];

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
      } // lib.optionalAttrs cfg.jupyter.enable {
        CODE_EXECUTION_ENGINE = "jupyter";
        CODE_EXECUTION_JUPYTER_URL = "http://127.0.0.1:${toString cfg.jupyter.port}";
      };
      # environmentFile = ""; # Useful for passing secrets to the service
    };

    # Jupyter code execution backend (localhost-only, no auth needed for local IPC)
    services.jupyter = lib.mkIf cfg.jupyter.enable {
      enable = true;
      ip = "127.0.0.1";
      port = cfg.jupyter.port;
      notebookConfig = ''
        c.ServerApp.token = ""
        c.ServerApp.password = ""
        c.ServerApp.disable_check_xsrf = True
        c.ServerApp.allow_origin = "*"
        c.ServerApp.allow_credentials = True
      '';
    };

    systemd.services.open-webui = {
      after = [
        "postgresql.service"
        "tailscaled.service"
      ] ++ lib.optional ollamaEnabled "ollama.service"
        ++ lib.optional llamaCppEnabled "llama-cpp.service"
        ++ lib.optional cfg.jupyter.enable "jupyter.service";

      requires = [
        "postgresql.service"
        "tailscaled.service"
      ] ++ lib.optional ollamaEnabled "ollama.service"
        ++ lib.optional llamaCppEnabled "llama-cpp.service"
        ++ lib.optional cfg.jupyter.enable "jupyter.service";

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
