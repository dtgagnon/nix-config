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

  cfg = config.${namespace}.services.copyparty-client;

  serviceName = "rclone-mount:.@copyparty";
in
{
  options.${namespace}.services.copyparty-client = {
    enable = mkBoolOpt false "Enable copyparty WebDAV client mounting via rclone.";
    serverUrl = mkOpt types.str "http://100.100.1.2:3923" "URL of the copyparty server.";
    username = mkOpt types.str "dtgagnon" "Username for WebDAV authentication.";
    mountPoint =
      mkOpt types.str "${config.home.homeDirectory}/Share"
        "Local directory where the share will be mounted.";
    healthCheckPath =
      mkOpt types.str "dtgagnon"
        "Subdirectory requiring auth, used by the liveness probe to detect anonymous-only mounts.";
    healthCheckInterval = mkOpt types.str "60s" "Interval between health-check timer firings.";
  };

  config = mkIf cfg.enable {
    # Override the rclone mount service for resilient mounting
    # Service name pattern: rclone-mount:<path>@<remote> with / replaced by .
    systemd.user.services.${serviceName} = {
      Unit = {
        # Wait for credentials to be written before mounting
        After = [ "rclone-config.service" ];
        Requires = [ "rclone-config.service" ];
        # Allow more restart attempts: 5 per 10 minutes
        StartLimitIntervalSec = 600;
        StartLimitBurst = 5;
      };
      Service = {
        ExecStartPre = lib.mkForce [
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.mountPoint}"
          # Clean up stale FUSE mounts; "-" prefix allows failure
          "-/run/wrappers/bin/fusermount -uz ${cfg.mountPoint}"
          # Wait for the copyparty server to become reachable (max ~6 min)
          # Exits 1 on timeout, which triggers Restart=on-failure
          "${pkgs.bash}/bin/bash -c 'for i in $(seq 36); do ${lib.getExe pkgs.curl} -sf --max-time 5 --head ${lib.escapeShellArg cfg.serverUrl} && exit 0; sleep 5; done; exit 1'"
        ];
        # Clean up FUSE mount on stop
        ExecStopPost = "-/run/wrappers/bin/fusermount -uz ${cfg.mountPoint}";
        RestartSec = 10;
      };
    };

    # Rclone retry options for transient network errors
    programs.rclone = {
      enable = true;

      remotes.copyparty = {
        config = {
          type = "webdav";
          url = cfg.serverUrl;
          vendor = "other";
          user = cfg.username;
          pacer_min_sleep = "0.01ms";
        };

        secrets.pass = config.sops.secrets.dtgagnon-copyparty-pass.path;

        mounts."/" = {
          enable = true;
          mountPoint = cfg.mountPoint;
          options = {
            vfs-cache-mode = "writes";
            dir-cache-time = "5s";
            use-cookies = true;
            # Retry options for transient failures
            retries = 5;
            retries-sleep = "1s";
            low-level-retries = 20;
            contimeout = "30s";
          };
        };
      };
    };

    # Health-check oneshot: restarts the mount if server is up but auth dir is missing
    systemd.user.services.copyparty-health-check = {
      Unit = {
        Description = "Copyparty mount liveness probe";
        # Only run when the mount is actually up
        ConditionPathIsMountPoint = cfg.mountPoint;
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.bash}/bin/bash"
          "-c"
          (lib.escapeShellArg ''
            ${lib.getExe pkgs.curl} -sf --max-time 5 --head ${lib.escapeShellArg cfg.serverUrl} \
              && ! test -d ${lib.escapeShellArg "${cfg.mountPoint}/${cfg.healthCheckPath}"} \
              && systemctl --user restart ${lib.escapeShellArg serviceName} \
              || true
          '')
        ];
      };
    };

    # Timer to fire the health check periodically
    systemd.user.timers.copyparty-health-check = {
      Unit.Description = "Periodic copyparty mount liveness probe";
      Timer = {
        OnUnitActiveSec = cfg.healthCheckInterval;
        OnBootSec = cfg.healthCheckInterval;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
