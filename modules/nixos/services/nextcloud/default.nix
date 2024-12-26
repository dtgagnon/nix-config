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
  cfg = config.${namespace}.services.nextcloud;
in
{
  options.${namespace}.services.nextcloud = {
    enable = mkBoolOpt false "Enable Nextcloud service";
    home = mkOpt types.path "/var/lib/nextcloud" "Nextcloud data directory";
    https = mkBoolOpt false "Enable HTTPS for Nextcloud";
    hostname = mkOpt types.str "nextcloud.example.com" "Hostname for Nextcloud";
    settings = mkOpt (types.attrsOf (types.listOf types.str)) { } "Additional Nextcloud settings";
  };

  config = mkIf cfg.enable {
    services.nextcloud = {
      enable = true;
      inherit (cfg) home https hostname settings;
    };
  };
}
