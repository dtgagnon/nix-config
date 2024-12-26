{ 
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.vaultwarden;
in
{
  options.${namespace}.services.vaultwarden = {
    enable = mkBoolOpt false "Enable Vaultwarden service";
    dbBackend = mkOpt (types.enum [ "sqlite" "postgresql" ]) "postgresql" "Database backend for Vaultwarden";
    environmentFile = mkOpt types.path "/var/lib/vaultwarden/.env" "Path to the environment file";
    config = mkOpt (types.attrsOf types.str) { } "Additional configuration options for Vaultwarden";
  };

  config = mkIf cfg.enable {
    #TODO: add vaultwarden config
  };
}
