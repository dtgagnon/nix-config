{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  inherit (lib.spirenix) mkOpt;

  cfg = config.spirenix.apps.claude-desktop;
in
{
  options.spirenix.apps.claude-desktop = {
    enable = mkEnableOption "Claude Desktop application";

    package = mkOption {
      type = types.package;
      default = pkgs.claude-desktop;
      description = "The Claude Desktop package to use";
    };

    mcpServers = mkOpt types.attrs { } ''
      MCP (Model Context Protocol) server configurations.
      Each key is the server name, value is the server configuration.
    '';

    extraConfig = mkOpt types.attrs { } ''
      Additional Claude Desktop configuration options.
    '';
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Claude Desktop configuration directory
    xdg.configFile."claude/config.json" = mkIf (cfg.mcpServers != { } || cfg.extraConfig != { }) {
      text = builtins.toJSON (
        cfg.extraConfig
        // {
          mcpServers = cfg.mcpServers;
        }
      );
    };
  };
}
