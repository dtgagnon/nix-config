{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.sabnzbd;
in
{
  options.${namespace}.services.sabnzbd = {
    enable = mkBoolOpt false "Enable the sabnzbd service";
    configFile = mkOpt types.str "/var/lib/sabnzbd/sabnzbd.ini" "Path to the config file";
  };

  config = mkIf cfg.enable {
    services.sabnzbd = {
      enable = true;
      package = pkgs.sabnzbd;
      user = "sabnzbd";
      group = "media";
      openFirewall = false;
      inherit (cfg) configFile;
    };
  };
}
