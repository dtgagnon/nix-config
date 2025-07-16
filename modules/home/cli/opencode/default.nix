{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.opencode;
in
{
  options.${namespace}.cli.opencode = {
    enable = mkBoolOpt false "Enable the OpenCode AI CLI tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.opencode ];
    xdg.configFile."opencode/opencode.json".text = ''
      {
        "$schema": "https://opencode.ai/config.json",
        "model": "ollama/devstral:24b",
        "provider": {
          "ollama": {
            "name": "Ollama",
            "npm": "@ai-sdk/openai-compatible",
            "options": {
              "baseURL": "http://127.0.0.1:11434/v1"
            },
            "models": {
              "devstral:24b": {
                "name": "Devstral 24B"
              },
              "gemma3:27b-it-qat": {
                "name": "Gemma 3 27B QAT"
              }
            }
          }
        }
      }
    '';
  };
}
