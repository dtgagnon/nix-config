{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.zoxide;
in 
{
  options.${namespace}.cli.zoxide = {
    enable = mkBoolOpt true "zoxide";
  };

  config = mkIf cfg.enable {
    programs.zoxide.enable = true;
  };
}
