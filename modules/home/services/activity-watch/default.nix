{ lib
, pkgs
, config
, namespace
, ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.services.activity-watch;
in
{
  options.${namespace}.services.activity-watch = {
    enable = mkEnableOption "Enable ActivityWatch service for the user";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.aw-qt ];
    services.activitywatch = {
      enable = true;
      package = pkgs.activitywatch; # was previously using pkgs.aw-server-rust #TODO Delete if works or works better with activitywatch now.
      # settings = { # in TOML
      #   port = 1234;
      #   custom_static = {
      #     my-custom-watcher = "${pkgs.my-custom-watcher}/share/my-custom-watcher/static";
      #     aw-keywatcher = "${pkgs.aw-keywatcher}/share/aw-keywatcher/static";
      #   };
      # };
      watchers = {
        aw-watcher-afk = {
          package = pkgs.activitywatch;
          settings = {
            timeout = 300;
            poll_time = 2;
          };
        };

        aw-watcher-window = {
          package = pkgs.activitywatch;
          settings = {
            poll_time = 1;
            # exclude_title = true;
          };
        };

        aw-watcher-web = {
          package = pkgs.activitywatch;
        };

        aw-watcher-input = {
          package = pkgs.activitywatch;
        };

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
        aw-watcher-vscode = mkIf config.spirenix.apps.vscode.enable {
          package = pkgs.activitywatch;
          settings.poll_time = 2;
        };
        aw-watcher-window-wayland = mkIf config.wayland.windowManager.hyprland.enable {
          package = pkgs.activitywatch;
          settings.poll_time = 1;
        };
      };
    };
  };
}
