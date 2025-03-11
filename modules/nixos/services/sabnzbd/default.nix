{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.sabnzbd;
in
{
  options.${namespace}.services.sabnzbd = {
    enable = mkBoolOpt false "Enable the sabnzbd service";
    configFile = mkOpt types.str "/var/lib/sabnzbd/sabnzbd.ini" "Path to the config file";
  };

  config = mkIf cfg.enable {
    services.sabnzbd = {
      enable = true;
      package = pkgs.sabnzbd;
      user = "sabnzbd";
      group = "media";
      openFirewall = false;
      inherit (cfg) configFile;
    };

    spirenix.user.home.file = ''
      __version__=19
      [misc]
      [logging]

      __version__ = 19
      [misc]
      host = 0.0.0.0
      port = 8081  # Changed from default 8080 to avoid conflicts
      https_port = 9090
      enable_https = 0
      auto_browser = 0
      check_new_rel = 1
      bandwidth_limit = 0
      cache_limit = 450M
      web_dir = Glitter
      language = en
      require_auth = 0
      auto_disconnect = 1
      pause_on_post_processing = 0

      [categories]
      [[*]]
      priority = 0
      pp = 3
      name = *
      script = Default
      dir =

      [logging]
      log_level = 1
      log_size = 5242880
      enable_cherrypy_logging = 0
      log_backups = 5

      [servers]
      [[newshosting]]
      username = 94jc77rc
      password = tempAdmin
      enable = 1
      name = newshosting
      fillserver = 0
      connections = 100
      ssl = 1
      host = news.newshosting.com
      timeout = 60
      displayname = Newshosting
      port = 563
      retention = 0

      [paths]
      download_dir = /var/lib/sabnzbd/incomplete
      complete_dir = /srv/media/downloads
      script_dir = /var/lib/sabnzbd/scripts
      nzb_backup_dir = /var/lib/sabnzbd/backup
      admin_dir = /var/lib/sabnzbd/admin
      dirscan_dir = /var/lib/sabnzbd/watch
      permissions = 0775

      [cleanup]
      enable_duplicate_detection = 1
      enable_meta_duplicate_detection = 0
      clean_up_download_dir = 1
    '';
  };
}
