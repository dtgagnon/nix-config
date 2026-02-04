{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf filterAttrs;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.opencode;

  # Transform claude-code mcpServers format to opencode mcp format
  transformMcpServer = _name: server:
    if server.type == "stdio" then {
      enabled = true;
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    }
    else if server.type == "http" then {
      enabled = true;
      type = "remote";
      url = server.url;
    } // (lib.optionalAttrs (server ? headers) { headers = server.headers; })
    else null;

  # Convert claude-code mcpServers to opencode format
  mcpServers = filterAttrs (_: v: v != null)
    (builtins.mapAttrs transformMcpServer config.programs.claude-code.mcpServers);
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

        "mcp": ${builtins.toJSON mcpServers},

        "provider": {
          "openrouter": {
            "npm": "@ai-sdk/openai-compatible",
            "options": {
              "baseURL": "https://openrouter.ai/api/v1",
              "apiKey": "{file:${config.sops.secrets.openrouter_api.path}}"
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
