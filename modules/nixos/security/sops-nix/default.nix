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
  cfg = config.${namespace}.security.sops-nix;
in 
{ 
  options.${namespace}.security.sops-nix = {
    enable = mkBoolOpt true "Enable sops secrets management";
  };
  
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sops ];
  };
}
