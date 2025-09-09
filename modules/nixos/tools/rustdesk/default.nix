{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.tools.rustdesk;
in
{
  options.${namespace}.tools.rustdesk = {
    enable = mkEnableOption "Enable rustdesk client";
    asService = mkEnableOption "Make rustdesk run in the background as a systemd system service";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rustdesk-flutter ];
    systemd.services.rustdesk-client-service = {
      description = "Runs rustdesk-flutter as a background systemd system-level service";
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
      after = [ "display-manager.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
        ExecStop = "pkill -f \"rustdesk --\"";
        PIDFile = "/run/rustdesk.pid";
        KillMode = "mixed";
        TimeoutStopSec = "30";
        User = "rustdesk";
        Group = "rustdesk";
        LimitNOFILE = "100000";
      };
    };
    users = {
      users.rustdesk = {
        isSystemUser = true;
        group = "rustdesk";
      };
      groups.rustdesk = { };
    };
  };
}
