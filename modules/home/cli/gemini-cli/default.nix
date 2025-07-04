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
    home.packages = [ pkgs.gemini-cli ];
    home.file.".gemini/settings.json".text = ''
      {
        "theme": "Default",
        "selectedAuthType": "oauth-personal",
        "preferredEditor": "nvim",
        "contextFileName": [ "GEMINI.md", "CLAUDE.md", "AGENTS.md" ],

        "mcpServers": {
          "nixos": {
            "command": "nix",
            "args": [ "run", "github:utensils/mcp-nixos", "--" ]
          },
          "playwrite": {
            "command": "npx",
            "args": [ "-y", "@executeautomation/playwright-mcp-server" ]
          },
          "sequential-thinking": {
            "command": "npx",
            "args": [ "-y", "@modelcontextprotocol/server-sequential-thinking" ]
          }
        }
      }
    '';
  };
}
