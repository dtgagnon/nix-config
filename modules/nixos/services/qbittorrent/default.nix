{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.qbittorrent;
in
{
  options.${namespace}.services.qbittorrent = {
    enable = mkBoolOpt false "Enable qBittorrent";
    port = mkOpt types.str "8080" "Declare the webui port";
    configDir = mkOpt types.str "/etc/qbittorrent" "The default configuration directory";
    dataDir = mkOpt types.str "/var/lib/qbittorrent" "Declare the application working directory";
    downDir = mkOpt types.str "/srv/media/downloads" "Declare the default torrent downlaod directory";
    user = mkOpt types.str "qbittorrent" "User the service runs as";
    group = mkOpt types.str "media" "Group the service user belongs to";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.qbittorrent-nox ];

    environment.variables = {
      QBT_WEBUI_PORT = "${cfg.port}";
      QBT_PROFILE = "${cfg.configDir}";

      QBT_SAVE_PATH = "${cfg.downDir}";

      QBT_ADD_STOPPED = "FALSE";
      QBT_CONFIRM_LEGAL_NOTICE = "TRUE";
    };

    systemd = {
      tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.downDir} 0750 ${cfg.user} ${cfg.group} -"
      ];
      services.qbittorrent = {
        description = "qBittorrent-nox daemon";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "notify";
          User = "qbittorrent";
          ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
          WorkingDirectory = "${cfg.dataDir}";
          Restart = "on-failure";
        };
      };
    };

    users.users.qbittorrent = {
      isSystemUser = true;
      group = "media";
      home = "${cfg.dataDir}";
    };

    sops.secrets.qbittorrent-webui = {
      owner = "${cfg.user}";
      mode = "0750";
    };

    environment.etc."qbittorrent/.config/qBittorrent/qBittorrent.conf".text = ''
      [Application]
      FileLogger\Age=1
      FileLogger\AgeType=1
      FileLogger\Backup=true
      FileLogger\DeleteOld=true
      FileLogger\Enabled=true
      FileLogger\MaxSizeBytes=66560
      FileLogger\Path=/var/lib/qbittorrent/.local/share/qBittorrent/logs

      [BitTorrent]
      Session\AnonymousModeEnabled=true
      Session\BandwidthSchedulerEnabled=true
      Session\DefaultSavePath=/srv/media/downloads
      Session\ExcludedFileNames=
      Session\FinishedTorrentExportDirectory=/srv/media/downloads/.torrent/done
      Session\GlobalMaxInactiveSeedingMinutes=4321
      Session\GlobalMaxRatio=3
      Session\GlobalMaxSeedingMinutes=4321
      Session\Port=61496
      Session\QueueingSystemEnabled=false
      Session\SSL\Port=25650
      Session\SubcategoriesEnabled=true
      Session\TempPath=/srv/media/downloads/dl
      Session\TempPathEnabled=true
      Session\TorrentExportDirectory=/srv/media/downloads/.torrent/dl
      Session\UseAlternativeGlobalSpeedLimit=false

      [Core]
      AutoDeleteAddedTorrentFile=Never

      [Meta]
      MigrationVersion=8

      [Network]
      Cookies=@Invalid()
      PortForwardingEnabled=false

      [Preferences]
      General\Locale=en
      MailNotification\req_auth=true
      Scheduler\end_time=@Variant(\0\0\0\xf\x4\xb8\x7f\0)
      WebUI\AuthSubnetWhitelist=100.100.0.0/16
      WebUI\AuthSubnetWhitelistEnabled=true
      WebUI\Password_PBKDF2="@ByteArray(W7Gxyc/YUtjij7+F/OuVjw==:43NrfiEa5KlXXYuxWSK7uozQZx7Qnp2AUYWU7B4FLI/8VmN0AqwqL/2cxtdqxxL/bVxII0/ZoVu5G29HQydqWg==)"

      [RSS]
      AutoDownloader\DownloadRepacks=true
      AutoDownloader\SmartEpisodeFilter=s(\\d+)e(\\d+), (\\d+)x(\\d+), "(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})", "(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})"
    '';
  };
}
