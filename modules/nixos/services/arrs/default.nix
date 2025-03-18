{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.arrs;
in
{
  options.${namespace}.services.arrs = {
    enable = mkBoolOpt false "Enable ARR services";
    dataDir = mkOpt types.str "/var/lib/arrs" "Declare a universal data directory for all ARR services";
    mediaDir = mkOpt types.str "/srv/media" "Declare a universal media directory for all ARR services";
  };

  config = mkIf cfg.enable {
    spirenix.user.extraGroups = [ "media" ];
    users.groups.media = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0775 root media -"
    ];
  };
}
