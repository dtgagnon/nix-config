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

        "theme": "catppuccin",
        "model": "ollama/qwen3:14b-32k",

        "mcp": {
          "nixos": {
            "enabled": true,
            "type": "local",
            "command": [ "nix", "run", "github:utensils/mcp-nixos", "--" ]
          },
          "playwrite": {
            "enabled": true,
            "type": "local",
            "command": [ "npx", "-y", "@executeautomation/playwright-mcp-server" ]
          },
        },

        "provider": {
          "openrouter": {
            "npm": "@ai-sdk/openai-compatible",
            "options": {
              "baseURL": "https://openrouter.ai/api/v1",
              "apiKey": "{file:${config.sops.secrets.openrouter_api.path}}"
            },
            "models": {}
          },
          "anthropic": {
            "options": {
              "baseURL": "https://api.anthropic.com/v1",
              "apiKey": "{file:${config.sops.secrets.anthropic_api.path}}"
            },
            "models": {}
          },
          "openai": {
            "options": {
              "baseURL": "https://api.openai.com/v1",
              "apiKey": "{file:${config.sops.secrets.openai_api.path}}"
            },
            "models": {}
          },
          "moonshot": {
            "npm": "@ai-sdk/openai-compatible",
            "options": {
              "baseURL": "https://api.moonshot.ai/v1",
              "apiKey": "{file:${config.sops.secrets.moonshot_api.path}}"
            },
            "models": {}
          },
          "ollama": {
            "name": "Ollama",
            "npm": "@ai-sdk/openai-compatible",
            "options": {
              "baseURL": "http://100.100.2.1:11434/v1"
            },
            "models": {
              "devstral:24b-16k": {
                "name": "devstral:24b-16k",
                "tools": true,
                "reasoning": false
              },
              "gpt-oss:20b": {
                "name": "gpt-oss:20b",
                "tools": true,
                "reasoning": true
              },
              "qwen3:14b-32k": {
                "name": "qwen3:14b-32k",
                "tools": true,
                "reasoning": true
              }
            }
          }
        }
      }
    '';
  };
}
