{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types concatStringsSep;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.copyparty;

  extraArgs = concatStringsSep " " cfg.extraArgs;
in
{
  options.${namespace}.services.copyparty = {
    enable = mkBoolOpt false "Enable the copyparty file sharing service.";
    package = mkOpt types.package pkgs.copyparty-most "Package providing the copyparty binary.";
    dataDir = mkOpt types.str "/var/lib/copyparty" "Directory for uploaded files and state.";
    address = mkOpt types.str "0.0.0.0" "Address the service listens on.";
    port = mkOpt types.port 3923 "Port the service listens on.";
    extraArgs = mkOpt (types.listOf types.str) [ "--no-guess-mime" ] "Additional command-line arguments passed to copyparty.";
    user = mkOpt types.str "copyparty" "User account running the service.";
    group = mkOpt types.str "copyparty" "Group owning service files.";
    openFirewall = mkBoolOpt false "Open the firewall for the configured port.";
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      home = cfg.dataDir;
      group = cfg.group;
    };

    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.copyparty = {
      description = "Copyparty file sharing service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/copyparty -a ${cfg.address}:${toString cfg.port} -v ${cfg.dataDir}" +
          lib.optionalString (extraArgs != "") " ${extraArgs}";
        Restart = "on-failure";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
