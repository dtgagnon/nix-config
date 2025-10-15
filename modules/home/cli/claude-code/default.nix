{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.cli.claude-code;
in
{
  options.${namespace}.cli.claude-code = {
    enable = mkBoolOpt false "Enable the claude ai assistant cli tool";

    statusLine = {
      enable = mkBoolOpt true "Enable status line in Claude Code";
      template = mkOpt types.str "{{cwd}} • {{git_branch}} {{git_status}}" "Status line template";
      showGitInfo = mkBoolOpt true "Show git information in status line";
      refreshInterval = mkOpt types.int 1000 "Status line refresh interval in milliseconds";
    };

    settings = mkOpt types.attrs {} "Additional Claude Code settings";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
      # MCP servers will be configured per-project in dev shells
    ];

    # Create sops template for Claude Code settings with secrets
    sops.templates."claude-code-settings.json" = {
      path = "${config.home.homeDirectory}/.claude/settings.json";
      content = builtins.toJSON (cfg.settings // {
        statusLine = {
          enabled = cfg.statusLine.enable;
          template = cfg.statusLine.template;
          showGitInfo = cfg.statusLine.showGitInfo;
          refreshIntervalMs = cfg.statusLine.refreshInterval;
        };
        mcpServers = {
          nixos = {
            transport = "stdio";
            command = "nix";
            args = [ "run" "github:utensils/mcp-nixos" "--" ];
          };
          ref = {
            type = "http";
            url = "https://api.ref.tools/mcp?apiKey=${config.sops.placeholder.ref_api}";
          };
          # Project-specific MCP servers should be configured in dev shells
          # using mcp-servers-nix.lib.mkConfig as shown in the examples
        };
      });
    };

    # Create ~/.claude directory
    home.file = {
      ".claude/agents/.keep".text = "";
    };
  };
}
