{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.nextcloud;
in
{
  options.${namespace}.services.nextcloud = {
    enable = mkBoolOpt false "Enable Nextcloud service";
    home = mkOpt types.path "/var/lib/nextcloud" "Nextcloud state directory";
    dataDir = mkOpt types.path "/srv/nextcloud" "Nextcloud data directory";
    https = mkBoolOpt false "Enable HTTPS for Nextcloud";
    hostname = mkOpt types.str "nextcloud.spirenet.link" "Hostname for Nextcloud";
    settings = mkOpt (types.attrsOf types.anything) { } "Additional Nextcloud settings";
  };

  config = mkIf cfg.enable {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud32;

      datadir = cfg.dataDir;
      home = cfg.home;
      hostName = cfg.hostname;
      https = cfg.https;

      # appstoreEnable = null;

      # autoUpdateApps = {
      #   enable = false;
      #   startAt = "05:00:00";
      # };

      # caching = {
      #   apcu = true;
      #   memcached = false;
      #   redis = false;
      # };

      # cli.memoryLimit = null;

      config = {
        adminuser = "admin";
        adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
        dbtype = "pgsql";
        dbhost = "localhost";
        dbname = "nextcloud";
        dbpassFile = null;
        dbtableprefix = null;
        dbuser = "nextcloud";
      };

      # settings = {
      #   lib.recursiveUpdate
      #     {
      #       default_phone_region = "";
      #       enabledPreviewProviders = [
      #         "OC\\Preview\\PNG"
      #         "OC\\Preview\\JPEG"
      #         "OC\\Preview\\GIF"
      #         "OC\\Preview\\BMP"
      #         "OC\\Preview\\XBitmap"
      #         "OC\\Preview\\Krita"
      #         "OC\\Preview\\WebP"
      #         "OC\\Preview\\MarkDown"
      #         "OC\\Preview\\TXT"
      #         "OC\\Preview\\OpenDocument"
      #       ];
      #       log_type = "syslog";
      #       loglevel = 2;
      #       mail_domain = null;
      #       mail_from_address = null;
      #       mail_send_plaintext_only = false;
      #       mail_sendmailmode = "smtp";
      #       mail_smtpauth = false;
      #       mail_smtpdebug = false;
      #       mail_smtphost = "127.0.0.1";
      #       mail_smtpmode = "smtp";
      #       mail_smtpname = "";
      #       mail_smtpport = 25;
      #       mail_smtpsecure = "";
      #       mail_smtpstreamoptions = { };
      #       mail_smtptimeout = 10;
      #       mail_template_class = "\\\\OC\\\\Mail\\\\EMailTemplate";
      #       overwriteprotocol = "";
      #       "profile.enabled" = false;
      #       skeletondirectory = "";
      #       trusted_domains = [ ];
      #       trusted_proxies = [ ];
      # } // cfg.settings;

      # configureRedis = true;

      # database.createLocally = false;



      # enableImagemagick = true;

      # extraApps = { };
      # extraAppsEnable = true;

      # fastcgiTimeout = 120;

      # imaginary.enable = false;

      # maxUploadSize = "512M";

      # nginx = {
      #   enableFastcgiRequestBuffering = false;
      #   hstsMaxAge = 15552000;
      # };
      #
      # notify_push = {
      #   bendDomainToLocalhost = false;
      #   dbhost = config.services.nextcloud.config.dbhost;
      #   dbname = config.services.nextcloud.config.dbname;
      #   dbpassFile = config.services.nextcloud.config.dbpassFile;
      #   dbtableprefix = config.services.nextcloud.config.dbtableprefix;
      #   dbtype = config.services.nextcloud.config.dbtype;
      #   dbuser = config.services.nextcloud.config.dbuser;
      #   enable = false;
      #   logLevel = "error";
      #   nextcloudUrl =
      #     "http${lib.optionalString config.services.nextcloud.https "s"}://${config.services.nextcloud.hostName}";
      #   package = pkgs.nextcloud-notify_push;
      #   socketPath = "/run/nextcloud-notify_push/sock";
      # };
      #
      # phpExtraExtensions = all: [ ];
      #
      # phpOptions = {
      #   catch_workers_output = "yes";
      #   display_errors = "stderr";
      #   error_reporting = "E_ALL & ~E_DEPRECATED & ~E_STRICT";
      #   expose_php = "Off";
      #   "opcache.fast_shutdown" = "1";
      #   "opcache.interned_strings_buffer" = "8";
      #   "opcache.max_accelerated_files" = "10000";
      #   "opcache.memory_consumption" = "128";
      #   "opcache.revalidate_freq" = "1";
      #   "openssl.cafile" = config.security.pki.caBundle;
      #   output_buffering = "0";
      #   short_open_tag = "Off";
      # };
      #
      # phpPackage = pkgs.php84;
      #
      # poolConfig = null;
      #
      # poolSettings = {
      #   pm = "dynamic";
      #   "pm.max_children" = "120";
      #   "pm.max_requests" = "500";
      #   "pm.max_spare_servers" = "18";
      #   "pm.min_spare_servers" = "6";
      #   "pm.start_servers" = "12";
      #   "pm.status_path" = "/status";
      # };
      #
      # secretFile = null;
      #
      # secrets = { };
      #

      #
      # webfinger = false;
    };

    sops.secrets.nextcloud-admin-pass = { };

    # For quick local exploration only (stored in Nix store).
    environment.etc."nextcloud-admin-pass".text = "changeme";
  };
}
