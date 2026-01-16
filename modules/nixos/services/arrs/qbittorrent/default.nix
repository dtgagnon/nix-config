{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.arrs.qbittorrent;
  vpnCfg = config.${namespace}.security.vpn;
in
{
  options.${namespace}.services.arrs.qbittorrent = {
    enable = mkBoolOpt false "Enable qBittorrent";
    port = mkOpt types.str "8080" "Declare the webui port";
    configDir = mkOpt types.str "/etc/qbittorrent" "The default configuration directory";
    dataDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/qbittorrent" "Declare the application working directory";
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
        after = [ "systemd-networkd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          User = "qbittorrent";
          ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --confirm-legal-notice";
          WorkingDirectory = "${cfg.dataDir}";
          Restart = "on-failure";
        };
      };
    };

    # # NAT-PMP keepalive for ProtonVPN (10.2.0.1 gateway)
    # systemd.services.qbittorrent-natpmp = mkIf (vpnCfg.provider == "proton-vpn" && vpnCfg.tailscaleCompat) {
    #   description = "qBittorrent NAT-PMP keepalive (ProtonVPN)";
    #   after = [ "qbittorrent.service" "network-online.target" ];
    #   wants = [ "network-online.target" ];
    #   wantedBy = [ "multi-user.target" ];
    #   partOf = [ "qbittorrent.service" ];
    #   path = [ pkgs.libnatpmp pkgs.coreutils pkgs.bash ];
    #   script = ''
    #     while true ; do
    #       date
    #       natpmpc -a 1 0 udp 60 -g 10.2.0.1 && natpmpc -a 1 0 tcp 60 -g 10.2.0.1 || { echo -e "ERROR with natpmpc command \a" ; break ; }
    #       sleep 45
    #     done
    #   '';
    #   serviceConfig = {
    #     Type = "simple";
    #     Restart = "always";
    #     RestartSec = 10;
    #   };
    # };

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
      Session\AlternativeGlobalDLSpeedLimit=5000
      Session\AlternativeGlobalUPSpeedLimit=1000
      Session\AnonymousModeEnabled=false
      Session\BTProtocol=TCP
      Session\BandwidthSchedulerEnabled=true
      Session\DefaultSavePath=/srv/media/downloads/qbt
      Session\DisableAutoTMMByDefault=false
      Session\DisableAutoTMMTriggers\CategorySavePathChanged=false
      Session\DisableAutoTMMTriggers\DefaultSavePathChanged=false
      Session\ExcludedFileNames=
      Session\FinishedTorrentExportDirectory=
      Session\GlobalMaxInactiveSeedingMinutes=-1
      Session\GlobalMaxRatio=-1
      Session\GlobalMaxSeedingMinutes=-1
      Session\Interface=wg-proton
      Session\InterfaceAddress=
      Session\InterfaceName=wg-proton
      Session\MaxConnectionsPerTorrent=-1
      Session\MaxUploads=8
      Session\Port=61496
      Session\Preallocation=true
      Session\QueueingSystemEnabled=false
      Session\SSL\Port=25650
      Session\SubcategoriesEnabled=false
      Session\TempPath=/srv/media/downloads/dl
      Session\TempPathEnabled=false
      Session\TorrentExportDirectory=
      Session\UseAlternativeGlobalSpeedLimit=true

      [Core]
      AutoDeleteAddedTorrentFile=IfAdded

      [Meta]
      MigrationVersion=8

      [Network]
      Cookies=@Invalid()
      PortForwardingEnabled=false

      [Preferences]
      General\Locale=en
      General\StatusbarExternalIPDisplayed=true
      MailNotification\req_auth=true
      Scheduler\end_time=@Variant(\0\0\0\xf\x4\xb8\x7f\0)
      WebUI\AuthSubnetWhitelist=100.100.0.0/16
      WebUI\AuthSubnetWhitelistEnabled=true
      WebUI\CSRFProtection=false
      WebUI\ClickjackingProtection=false
      WebUI\HostHeaderValidation=false
      WebUI\Password_PBKDF2="@ByteArray(W7Gxyc/YUtjij7+F/OuVjw==:43NrfiEa5KlXXYuxWSK7uozQZx7Qnp2AUYWU7B4FLI/8VmN0AqwqL/2cxtdqxxL/bVxII0/ZoVu5G29HQydqWg==)"

      [RSS]
      AutoDownloader\DownloadRepacks=true
      AutoDownloader\SmartEpisodeFilter=s(\\d+)e(\\d+), (\\d+)x(\\d+), "(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})", "(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})"
    '';
  };
}
