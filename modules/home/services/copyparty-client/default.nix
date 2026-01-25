{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.services.copyparty-client;
in
{
  options.${namespace}.services.copyparty-client = {
    enable = mkBoolOpt false "Enable copyparty WebDAV client mounting via rclone.";
    serverUrl = mkOpt types.str "http://100.100.1.2:3923" "URL of the copyparty server.";
    username = mkOpt types.str "dtgagnon" "Username for WebDAV authentication.";
    mountPoint = mkOpt types.str "${config.home.homeDirectory}/Share" "Local directory where the share will be mounted.";
  };

  config = mkIf cfg.enable {
    # Override the rclone mount service to handle stale FUSE mounts
    # Service name pattern: rclone-mount:<path>@<remote> with / replaced by .
    systemd.user.services."rclone-mount:.@copyparty" = {
      Unit.StartLimitIntervalSec = 30;
      Unit.StartLimitBurst = 3;
      Service = {
        # Override to include both mkdir (from upstream rclone module) and stale mount cleanup
        # The "-" prefix allows fusermount to fail without stopping the service
        ExecStartPre = lib.mkForce [
          "${pkgs.coreutils}/bin/mkdir -p ${cfg.mountPoint}"
          "-${pkgs.fuse}/bin/fusermount -uz ${cfg.mountPoint}"
        ];
        # Add delay between restart attempts
        RestartSec = 5;
      };
    };

    # Configure rclone with copyparty WebDAV remote
    programs.rclone = {
      enable = true;

      remotes.copyparty = {
        # Regular configuration options
        config = {
          type = "webdav";
          url = cfg.serverUrl;
          vendor = "other";
          user = cfg.username;
          pacer_min_sleep = "0.01ms";
        };

        # Secrets loaded from file at activation time
        secrets.pass = config.sops.secrets.dtgagnon-copyparty-pass.path;

        # Mount configuration
        mounts."/" = {
          enable = true;
          mountPoint = cfg.mountPoint;
          options = {
            vfs-cache-mode = "writes";
            dir-cache-time = "5s";
            # Enable session cookies to maintain auth state across requests
            # Helps prevent 401 errors on long-running mounts (copyparty issue #272)
            use-cookies = true;
          };
        };
      };
    };
  };
}
