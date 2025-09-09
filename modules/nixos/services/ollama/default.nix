{ lib
, pkgs
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
      package = pkgs.ollama.override { acceleration = "cuda"; };
      acceleration = "cuda";
      host = "0.0.0.0";
      port = 11434;
      home = "/var/lib/ollama";
      models = "/var/lib/ollama/models";
      # loadModels = [
      #   "devstral:24b"
      #   "gemma3:27b"
      #   "gpt-oss:20b"
      #   "qwen3:14b"
      # ];
      environmentVariables = { };
    };
  };
}
