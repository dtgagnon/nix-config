{ 
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.tools.virtualisation.proxmox;
in
{
  options.${namespace}.tools.virtualisation.proxmox = {
    enable = mkBoolOpt false "Enable Proxmox VE";
  };

  config = mkIf cfg.enable {
    # proxmox configuration goes here
  };
}
