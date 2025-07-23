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
      host = "0.0.0.0";
      port = 11434;
      home = "/var/lib/ollama";
      # models = "/var/lib/ollama/models";
      loadModels = [ ]; # a list of models to auto-download with start of the service
      environmentVariables = {
        OLLAMA_HOST=100.100.2.1:11434;
      };
    };
  };
}
