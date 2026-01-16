# MCP Servers package collection
# For now, just exports the mxroute MCP server
# Add more servers here as needed
{
  lib,
  stdenvNoCC,
  python3,
  bash,
  ...
}:
import ./mxroute-mcp.nix {
  inherit
    lib
    stdenvNoCC
    python3
    bash
    ;
}
