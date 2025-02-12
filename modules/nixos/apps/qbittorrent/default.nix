{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.qbittorrent;
in
{
  options.${namespace}.apps.qbittorrent = {
    enable = mkBoolOpt false "Enable qBittorrent";
    port = mkOpt types.str "8080" "Declare the webui port";
    dataDir = mkOpt types.str "/var/lib/qbittorrent" "Declare the application working directory";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.qbittorrent-nox ];

    systemd.services.qbittorrent = {
      description = "qBittorrent-nox daemon";
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        # Run as dedicated 'qbittorrent' user
        User = "qbittorrent";
        # Launch qbittorrent-nox w/ desired webui port
        ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=${cfg.port}";
        # Set a working directory
        WorkingDirectory = "${cfg.dataDir}";
        # Restart the service automatically upon failure
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
