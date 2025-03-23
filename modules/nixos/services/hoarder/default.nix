{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.hoarder;
in
{
  options.${namespace}.services.hoarder = {
    enable = mkBoolOpt false "Enable hoarder, a bookmarks manager";
    user = mkOpt types.str "hoarder" "Declare the user that the service will belong to";
    group = mkOpt types.str "hoarder" "Declare the group that the service will belong to";
    dataDir = mkOpt types.str "/var/lib/hoarder" "Declare the directory to store the service data";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.hoarder ];
    systemd = {
      tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      ];
      services.hoarder = {
        description = "Hoarder background service";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "notify"; #TODO: identify the correct type
          User = "${cfg.user}";
          ExecStart = "${pkgs.hoarder}/bin/hoarder";
          WorkingDirectory = "${cfg.dataDir}";
          Restart = "on-failure";
        };
      };
    };

    users.users.${cfg.user} = {
      group = cfg.group;
      isSystemUser = true;
      home = cfg.dataDir;
    };
  };
}
