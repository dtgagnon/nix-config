{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  options.${namespace}.services.mcp = {
    enable = mkEnableOption "MCP services";
  };
}
