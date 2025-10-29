{ lib
, pkgs
, config
, namespace
, ...
}:

let
  inherit (lib) mkIf mkEnableOption attrByPath;
  cfg = config.${namespace}.services.activity-watch;
  withHyprland = attrByPath [ "wayland" "windowManager" "hyprland" "enable" ] false config;
  hyprlandSystemd = attrByPath [ "wayland" "windowManager" "hyprland" "systemd" "enable" ] false config;
  waybarEnabled = attrByPath [ "programs" "waybar" "enable" ] false config;
in
{
  options.${namespace}.services.activity-watch = {
    enable = mkEnableOption "Enable ActivityWatch service for the user.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.aw-qt ];
    services.activitywatch = {
      enable = true;
      package = pkgs.activitywatch; # was previously using pkgs.aw-server-rust #TODO Delete if works or works better with activitywatch now.
      watchers = {
        aw-watcher-afk = {
          package = pkgs.activitywatch;
          settings = {
            timeout = 300;
            poll_time = 2;
          };
        };

        aw-watcher-window-wayland = mkIf config.wayland.windowManager.hyprland.enable {
          package = pkgs.aw-watcher-window-wayland;
          settings.poll_time = 1;
        };

        # aw-watcher-web = {
        #   package = pkgs.aw-watcher-web;
        # };

        # aw-watcher-vscode = mkIf config.spirenix.apps.vscode.enable {
        #   package = pkgs.aw-watcher-vscode;
        #   settings.poll_time = 2;
        # };
        # aw-watcher-input = {
        #   package = pkgs.aw-watcher-input;
        # };
        # name-of-watcher = {
        #   executable = "";
        #   extraOptions = [ "" ];
        #   name = "";
        #   package = pkgs.activitywatch;
        #   settings = {
        #     # in TOML
        #     enable_greetings = true;
        #     poll_time = 2;
        #     timeout = 300;
        #   };
        #   settingsFilename = "config.toml";
        # };
      };
    };

    # Fix aw-watcher-afk for Wayland/Hyprland
    systemd.user.services.activitywatch-watcher-aw-watcher-afk = mkIf config.wayland.windowManager.hyprland.enable {
      Unit = {
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Environment = [
          "WAYLAND_DISPLAY=wayland-1"
          "XDG_SESSION_TYPE=wayland"
        ];
      };
    };

    systemd.user.services.aw-qt = {
      Unit = {
        Description = "ActivityWatch Tray";
        After = [ "waybar.service" "graphical-session.target" ];
        Wants = lib.optionals waybarEnabled [ "waybar.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.aw-qt}/bin/aw-qt";
        Restart = "on-failure";
      };
      Install = {
        WantedBy =
          [ "graphical-session.target" ]
          ++ lib.optionals hyprlandSystemd [ "wayland-session@Hyprland.target" ];
      };
    };

    spirenix.desktop.hyprland.extraExec =
      lib.optionals
        (
          withHyprland
          && !hyprlandSystemd
        ) [ "systemctl --user start aw-qt.service" ];
  };
}
