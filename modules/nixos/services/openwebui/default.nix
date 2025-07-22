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
      host = "127.0.0.1";
      port = 11435;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OLLAMA_API_BASE_URL = "http://100.100.2.1:11434";
        WEBUI_AUTH = "False";
      };
      # environmentFile = ""; # Useful for passing secrets to the service
    };
  };
}
