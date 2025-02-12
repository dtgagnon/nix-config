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
    dataDir = mkOpt types.str "/var/lib/qbittorrent" "Declare the application working directory";
    downDir = mkOpt types.str "/srv/media/downloads" "Declare the application working directory";
    user = mkOpt types.str "qbittorrent" "User the service runs as";
    group = mkOpt types.str "media" "Group the service user belongs to";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.qbittorrent-nox ];

    environment.variables = {
      QBT_WEBUI_PORT = "${cfg.port}";
      QBT_SAVE_PATH = "${cfg.downDir}";
      QBT_ADD_STOPPED = "FALSE";
    };

    systemd-tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.downDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.qbittorrent = {
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

    users.users.qbittorrent = {
      isSystemUser = true;
      group = "media";
      home = "${cfg.dataDir}";
    };

    # No firewall permissions since this will only be accessed via tailscale
  };
}
