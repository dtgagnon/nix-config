{ lib
, pkgs
, config
, namespace
, ...
}:

let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.activity-watch;
in
{
  options.${namespace}.services.activity-watch = {
    enable = mkBoolOpt false "Enable ActivityWatch service for the user";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.aw-qt ];
    services.activitywatch = {
      enable = true;
      package = pkgs.aw-server-rust;
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

        aw-watcher-windows = {
          package = pkgs.activitywatch;
          settings = {
            poll_time = 1;
            exclude_title = true;
          };
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
      };
    };
  };
}
