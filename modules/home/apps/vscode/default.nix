{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.vscode;
in
{
  options.${namespace}.apps.vscode = {
    enable = mkBoolOpt false "Enable vscode";
    extensions = mkOpt (types.listOf types.str) [ ] "List of extensions to install as strings";
  };

  config = mkIf cfg.enable {
    programs.vscode.enable = true;
  };
}
