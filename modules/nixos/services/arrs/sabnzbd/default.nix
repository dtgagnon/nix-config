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
in
{
  # Module options configuration
  # Defines all user-configurable settings for the SABnzbd service
  options.${namespace}.services.arrs.sabnzbd = {
    enable = mkBoolOpt false "Enable the sabnzbd service";
    user = mkOpt types.str "usenet" "The user that the sabnzbd will run as";
    group = mkOpt types.str "media" "The group that sabnzbd belongs to";

    stateDir = mkOpt types.path "${config.spirenix.services.arrs.dataDir}/sabnzbd" "Directory for Sabnzbd state";
    package = mkOpt types.package pkgs.sabnzbd "The package to use for SABnzbd";
    guiPort = mkOpt types.port 8081 "The port that SABnzbd's GUI will listen on for incomming connections.";
    openFirewall = mkBoolOpt false "Open firewall for SABnzbd";
    whitelistHostnames = mkOpt (types.listOf types.str) [ config.networking.hostName ] "A list of hostnames that are allowed to connect to SABnzbd";
    whitelistRanges = mkOpt (types.listOf types.str) [ "100.100.0.0/16" ] "A list of IP ranges that are allowed to connect to SABnzbd";
  };

  config =
    let
      # Helper function to safely concatenate strings with commas
      # Only adds commas if the input list is non-empty
      concatStringsCommaIfExists = with lib.strings;
        stringList: (
          optionalString (builtins.length stringList > 0) (
            concatStringsSep "," stringList
          )
        );

      # Base configuration for SABnzbd (non-secret settings)
      sabnzbdConfig = {
        misc = {
          # Dynamic host binding based on firewall settings
          host =
            if cfg.openFirewall
            then "0.0.0.0"  # Listen on all interfaces if firewall is open
            else "100.100.1.2"; # Listen only on localhost if firewall is closed
          port = cfg.guiPort;
          download_dir = "${config.spirenix.services.arrs.mediaDir}/downloads/usenet/.incomplete";
          complete_dir = "${config.spirenix.services.arrs.mediaDir}/downloads/usenet/complete";
          dirscan_dir = "${config.spirenix.services.arrs.mediaDir}/usenet/watch";
          # host_whitelist = concatStringsCommaIfExists cfg.whitelistHostnames;
          local_ranges = concatStringsCommaIfExists cfg.whitelistRanges;
          permissions = "775";
        };
        logging = {
          log_level = 1;
          log_size = 5242880;
          enable_cherrypy_logging = 0;
          log_backups = 5;
        };
        cleanup = {
          enable_duplicate_detection = 1;
          enable_meta_duplicate_detection = 0;
          clean_up_download_dir = 1;
        };
      };

      # Server credentials template for sops injection
      serverCredentials = ''
        [servers]
        [[newshosting]]
        username = ${config.sops.placeholder."newshosting/username"}
        password = '${config.sops.placeholder."newshosting/password"}'
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
      '';

    in
    mkIf cfg.enable {
      # Main service configuration
      services.sabnzbd = {
        enable = true;
        package = cfg.package;
        user = "${cfg.user}";
        group = "${cfg.group}";
        settings = {
          misc = sabnzbdConfig.misc;
          logging = sabnzbdConfig.logging;
          cleanup = sabnzbdConfig.cleanup;
        };
      };

      # Systemd service dependencies and secrets injection
      systemd.services.sabnzbd = {
        after = [ "tailscaled.service" ];
        requires = [ "tailscaled.service" ];
        preStart = lib.mkAfter ''
          # Inject server credentials with secrets into the config file
          if ! grep -q "^\[servers\]" /var/lib/sabnzbd/sabnzbd.ini 2>/dev/null; then
            cat ${config.sops.templates."sabnzbd-servers".path} >> /var/lib/sabnzbd/sabnzbd.ini
          fi
        '';
      };

      # Firewall configuration
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.guiPort ];

      # System user and group configuration
      users = {
        groups.${cfg.group} = { };
        users.${cfg.user} = {
          isSystemUser = true;
          group = "${cfg.group}";
        };
      };

      # Directory structure setup
      # Creates all necessary directories with appropriate permissions
      systemd.tmpfiles.rules = [
        # Media directory structure
        # All directories owned by usenet:media with appropriate permissions
        "d '${config.spirenix.services.arrs.mediaDir}/usenet'             0755 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/.incomplete' 0755 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/.watch'      0755 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/manual'      0775 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/liadarr'     0775 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/radarr'      0775 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/sonarr'      0775 usenet media - -"
      ];

      # Secrets management
      # Configures secure storage for sensitive credentials
      sops = {
        secrets = {
          "newshosting/username".owner = "${cfg.user}";
          "newshosting/password".owner = "${cfg.user}";
        };
        templates = {
          "sabnzbd-servers" = {
            content = serverCredentials;
            owner = "${cfg.user}";
          };
        };
      };
    };
}
