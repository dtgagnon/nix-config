{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.homemodule.directory;
in
{
  options.${namespace}.homemodule.directory = {
    enable = mkEnableOption "Enable XXXXX module";
  };

  config = mkIf cfg.enable {
    
  };
}
