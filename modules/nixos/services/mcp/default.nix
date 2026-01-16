{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.mcp;
in
{
  options.${namespace}.services.mcp = {
    enable = mkEnableOption "MCP services";
    mxroute.enable = mkBoolOpt false "Make the mxroute MCP server package available";
  };

  config = mkIf cfg.enable {
    # Make the package available system-wide
    environment.systemPackages = mkIf cfg.mxroute.enable [ pkgs.spirenix.mcp-servers ];
  };
}
