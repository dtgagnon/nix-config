{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.gemini-cli;
in
{
  options.${namespace}.cli.gemini-cli = {
    enable = mkBoolOpt false "Enable the Google Gemini AI CLI tool";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nur.repos.lonerOrz.gemini-cli
      nodejs
      playwright-driver.browsers
      playwright-mcp
    ];
    home.file.".gemini/settings.json".text = ''
      {
        "general": {
          "checkpointing": {
            "enabled": true
          },
          "preferredEditor": "nvim",
          "vimMode": false,
          "previewFeatures": true
        },
        "context": {
          "fileName": [
            "GEMINI.md",
            "CLAUDE.md",
            "AGENTS.md"
          ]
        },
        "mcpServers": {
          "nixos": {
            "command": "nix",
            "args": [
              "run",
              "github:utensils/mcp-nixos",
              "--"
            ]
          },
        "security": {
          "auth": {
            "selectedType": "oauth-personal"
          }
        },
        "ui": {
          "theme": "Default"
        }
      }
    '';
  };
}
