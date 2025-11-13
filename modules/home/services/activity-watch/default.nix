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

    #FIX: Watchers must start after main ActivityWatch service and graphical session
    systemd.user.services = {
      activitywatch-watcher-aw-watcher-afk = {
        Unit = {
          After = [ "activitywatch.service" "graphical-session.target" ];
          Wants = [ "activitywatch.service" ];
        };
        Service.Environment = mkIf anyWaylandWM [
          "WAYLAND_DISPLAY=wayland-1"
          "XDG_SESSION_TYPE=wayland"
        ];
      };

      activitywatch-watcher-aw-watcher-window-wayland = mkIf anyWaylandWM {
        Unit = {
          After = [ "activitywatch.service" "graphical-session.target" ];
          Wants = [ "activitywatch.service" ];
        };
        Service.Environment = [
          "WAYLAND_DISPLAY=wayland-1"
          "XDG_SESSION_TYPE=wayland"
        ];
      };
    };

    spirenix.desktop.addons.sysbar.sysTrayApps = [ "aw-qt" ];
  };
}
