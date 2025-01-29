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
in {
  options.${namespace}.services.activity-watch = {
    enable = mkBoolOpt false "Enable ActivityWatch service";
  };

  config = mkIf cfg.enable {
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
      # watchers = {
      #   <name> = {
      #     executable = "";
      #     extraOptions = [ "" ];
      #     name = "";
      #     package = pkgs.activitywatch;
      #     settings = { # in TOML
      #       poll_time = 2;
      #       timeout = 300;
      #     };
      #     settingsFilename = "<name>.toml";
      #   };

      #   aw-watcher-afk = {
      #     package = pkgs.activitywatch;
      #     settings = {
      #       timeout = 300;
      #       poll_time = 2;
      #     };
      #   };

      #   aw-watcher-windows = {
      #     package = pkgs.activitywatch;
      #     settings = {
      #       poll_time = 1;
      #       exclude_title = true;
      #     };
      #   };

      #   my-custom-watcher = {
      #     package = pkgs.my-custom-watcher;
      #     executable = "mcw";
      #     settings = {
      #       hello = "there";
      #       enable_greetings = true;
      #       poll_time = 5;
      #     };
      #     settingsFilename = "config.toml";
      #   };
      # };
    };

    environment.systemPackages = with pkgs; [
      aw-qt
    ];

    # Add any additional configuration here, such as:
    # - System service configuration
    # - Required packages
    # - File permissions
    # - Port configurations
    # - Dependencies
  };
}
