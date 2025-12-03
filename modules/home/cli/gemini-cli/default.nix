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
        #   "playwrite": {
        #     "command": "nix",
        #     "args": [
        #       "run",
        #       "nixpkgs#playwright-mcp"
        #     ],
        #     "env": {
        #       "PLAYWRIGHT_BROWSERS_PATH": "${pkgs.playwright-driver.browsers}",
        #       "PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS": "true",
        #       "PLAYWRIGHT_NODEJS_PATH": "${pkgs.nodejs}/bin/node",
        #       "PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH": "${pkgs.playwright-driver.browsers}/chromium-1134/chrome-linux/chrome"
        #     }
        #   }
        # },
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
