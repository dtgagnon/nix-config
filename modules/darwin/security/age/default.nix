{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.security.age;
in 
{ 
  options.${namespace}.security.age = {
    enable = mkBoolOpt true "Enable age encryption";
  };
  
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.age ];
  };
}
