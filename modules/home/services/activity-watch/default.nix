{ lib
, pkgs
, config
, namespace
, ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.activity-watch;

  anyWaylandWM = lib.any (wm: wm.enable or false) (lib.attrValues config.wayland.windowManager);
in
{
  options.${namespace}.services.activity-watch = {
    enable = mkEnableOption "Enable ActivityWatch service for the user.";
  };

  config = mkIf cfg.enable {
    services.activitywatch = {
      enable = true;
      package = pkgs.activitywatch;
      watchers = {
        aw-watcher-afk = {
          package = pkgs.activitywatch;
          settings = {
            timeout = 300;
            poll_time = 2;
          };
        };

        aw-watcher-window-wayland = mkIf anyWaylandWM {
          package = pkgs.aw-watcher-window-wayland;
          settings.poll_time = 1;
        };
      };
    };

    #FIX: Main service must wait for Wayland compositor, watchers will inherit ordering
    systemd.user.services = {
      activitywatch = mkIf anyWaylandWM {
        Unit = {
          After = [ "wayland-session@Hyprland.target" ];
        };
        Service = {
          # Add restart on failure to handle any remaining race conditions
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      activitywatch-watcher-aw-watcher-afk = {
        Service = {
          # DISPLAY needed for pynput's X11 backend fallback
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };

      activitywatch-watcher-aw-watcher-window-wayland = mkIf anyWaylandWM {
        Unit = {
          After = [ "wayland-session@Hyprland.target" ];
        };
        Service = {
          # Give Hyprland compositor time to initialize socket
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
    };

    spirenix.desktop.addons.sysbar.sysTrayApps = [
      {
        name = "aw-qt";
        package = pkgs.activitywatch;
      }
    ];

    # Override aw-qt service to add startup delay for system tray availability
    systemd.user.services.aw-qt = mkIf anyWaylandWM {
      Service = {
        # Give waybar's system tray time to fully initialize
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        RestartSec = "5s";
      };
    };

    spirenix.preservation.directories = [
      ".local/share/activitywatch"
    ];
  };
}
