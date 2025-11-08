{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.apps.claude-desktop;
in
{
  options.${namespace}.apps.claude-desktop = {
    enable = mkEnableOption "Claude Desktop application";
    mcpServers = mkOpt types.attrs { } ''
      MCP (Model Context Protocol) server configurations.
      Each key is the server name, value is the server configuration.
    '';
    extraConfig = mkOpt types.attrs { } ''
      Additional Claude Desktop configuration options.
    '';
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.claude-desktop ];

    # Desktop entry for application launcher
    xdg.desktopEntries.claude-desktop = {
      name = "Claude Desktop";
      exec = "claude-desktop %U";
      icon = "claude-desktop";
      comment = "AI assistant from Anthropic";
      categories = [ "Development" "Utility" "Network" ];
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "claude-desktop";
      };
    };

    # Claude Desktop configuration directory
    # xdg.configFile."claude/config.json" = mkIf (cfg.mcpServers != { } || cfg.extraConfig != { }) {
    #   text = builtins.toJSON (
    #     cfg.extraConfig
    #     // {
    #       mcpServers = cfg.mcpServers;
    #     }
    #   );
    # };
  };
}
