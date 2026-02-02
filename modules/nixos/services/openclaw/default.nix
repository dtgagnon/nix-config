{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.${namespace}.services.openclaw;
in
{
  options.${namespace}.services.openclaw = {
    enable = mkEnableOption "OpenClaw self-hosted AI assistant";

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/openclaw";
      description = "Directory for OpenClaw workspace, memory, and session data";
    };

    port = mkOption {
      type = types.port;
      default = 18789;
      description = "Port for the OpenClaw gateway dashboard";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to bind the gateway to. Use 0.0.0.0 for all interfaces.";
    };

    user = mkOption {
      type = types.str;
      default = "openclaw";
      description = "User account under which OpenClaw runs";
    };

    group = mkOption {
      type = types.str;
      default = "openclaw";
      description = "Group under which OpenClaw runs";
    };
  };

  config = mkIf cfg.enable {
    # Persistence for openclaw data
    ${namespace}.system.preservation.extraSysDirs = [ cfg.dataDir ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    systemd.services.openclaw = {
      description = "OpenClaw AI Assistant Gateway";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        HOME = cfg.dataDir;
        OPENCLAW_DATA_DIR = cfg.dataDir;
        NODE_ENV = "production";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${lib.getExe pkgs.${namespace}.openclaw} gateway --bind ${cfg.bindAddress} --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ cfg.dataDir ];
      };
    };
  };
}
