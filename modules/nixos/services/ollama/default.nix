{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.services.ollama;
in
{
  options.${namespace}.services.ollama = {
    enable = mkEnableOption "Enable ollama for local LLM serving";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = "cuda";
      host = "127.0.0.1";
      port = 11434;
      home = "/var/lib/ollama";
      # models = "/var/lib/ollama/models";
      loadModels = [
        "devstral:24b"
        "gemma3:27b"
        "qwen3:14b"
      ]; # a list of models to auto-download with start of the service
      environmentVariables = { };
    };
  };
}
