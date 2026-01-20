{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.arrs.sabnzbd;
  arrsMediaDir = config.${namespace}.services.arrs.mediaDir;
in
{
  options.${namespace}.services.arrs.sabnzbd = {
    enable = mkBoolOpt false "Enable the sabnzbd service";
    user = mkOpt types.str "sabnzbd" "The user that sabnzbd will run as";
    group = mkOpt types.str "media" "The group that sabnzbd belongs to";
    package = mkOpt types.package pkgs.sabnzbd "The package to use for SABnzbd";
    openFirewall = mkBoolOpt false "Open firewall for SABnzbd";
    whitelistRanges = mkOpt (types.listOf types.str) [ "100.100.0.0/16" ] "IP ranges allowed to connect to SABnzbd";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        "sabnzbd/api-key" = { };
        "sabnzbd/nzb-key" = { };
        "newshosting/username" = { };
        "newshosting/password" = { };
      };
      templates."sabnzbd-servers" = {
        owner = cfg.user;
        group = cfg.group;
        content = ''
          [misc]
          api_key = ${config.sops.placeholder."sabnzbd/api-key"}
          nzb_key = ${config.sops.placeholder."sabnzbd/nzb-key"}

          [servers]
          [[newshosting]]
          name = newshosting
          displayname = Newshosting
          host = news.newshosting.com
          port = 563
          username = ${config.sops.placeholder."newshosting/username"}
          password = ${config.sops.placeholder."newshosting/password"}
          connections = 100
          ssl = 1
          enable = 1
          fillserver = 0
          timeout = 60
          retention = 0
        '';
      };
    };
    services.sabnzbd = {
      enable = true;
      package = cfg.package;
      user = cfg.user;
      group = cfg.group;
      openFirewall = cfg.openFirewall;

      # Allow SABnzbd to manage its own config (API keys, categories, etc.)
      allowConfigWrite = true;

      # Inject server credentials via sops
      secretFiles = [ config.sops.templates."sabnzbd-servers".path ];

      settings = {
        misc = {
          host = if cfg.openFirewall then "0.0.0.0" else "100.100.1.2";
          port = 8081;
          download_dir = "${arrsMediaDir}/downloads/usenet/.incomplete";
          complete_dir = "${arrsMediaDir}/downloads/usenet/complete";
          dirscan_dir = "${arrsMediaDir}/downloads/usenet/watch";
          local_ranges = lib.concatStringsSep "," cfg.whitelistRanges;
          permissions = "775";
        };
        logging = {
          log_level = 1;
          log_size = 5242880;
          log_backups = 5;
        };
        categories = {
          "*" = {
            name = "*";
            order = 0;
            pp = 3;
            script = "None";
            dir = "";
            newzbin = "";
            priority = 0;
          };
          movies = {
            name = "movies";
            order = 1;
            pp = "";
            script = "Default";
            dir = "";
            newzbin = "";
            priority = -100;
          };
          tv = {
            name = "tv";
            order = 2;
            pp = "";
            script = "Default";
            dir = "";
            newzbin = "";
            priority = -100;
          };
          music = {
            name = "music";
            order = 3;
            pp = "";
            script = "Default";
            dir = "";
            newzbin = "";
            priority = -100;
          };
          software = {
            name = "software";
            order = 4;
            pp = "";
            script = "Default";
            dir = "";
            newzbin = "";
            priority = -100;
          };
          books = {
            name = "books";
            order = 5;
            pp = "";
            script = "Default";
            dir = "";
            newzbin = "";
            priority = -100;
          };
        };
      };
    };

    # Require tailscale for network access
    systemd.services.sabnzbd = {
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
    };

    # Media directory structure
    systemd.tmpfiles.rules = [
      "d '${arrsMediaDir}/downloads/usenet'             0775 ${cfg.user} ${cfg.group} - -"
      "d '${arrsMediaDir}/downloads/usenet/.incomplete' 0775 ${cfg.user} ${cfg.group} - -"
      "d '${arrsMediaDir}/downloads/usenet/complete'    0775 ${cfg.user} ${cfg.group} - -"
      "d '${arrsMediaDir}/downloads/usenet/watch'       0775 ${cfg.user} ${cfg.group} - -"
    ];
  };
}
