{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.vscode.extensions.blockman;
in
{
  options.${namespace}.apps.vscode.extensions.blockman = {
    enable = mkBoolOpt false "Enable blockman extension and configuration";
  };

  config = mkIf cfg.enable {
    spirenix.apps.vscode.extensions = [ pkgs.vscode-extensions ];
  };
}
