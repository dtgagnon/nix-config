{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.opencode;
in
{
  options.${namespace}.cli.opencode = {
    enable = mkBoolOpt false "Enable the OpenCode AI CLI tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.opencode ];
  };
}
