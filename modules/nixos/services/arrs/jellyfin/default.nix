{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.arrs.jellyfin;
in
{
  options.${namespace}.services.arrs.jellyfin = {
    enable = mkBoolOpt false "Enable Jellyfin service";
    dataDir = mkOpt types.path "${config.spirenix.services.arrs.dataDir}/jellyfin" "Data directory for Jellyfin";
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      group = "media";
      inherit (cfg) dataDir;
      openFirewall = false;
    };

    # Allow only specific device to access Jellyfin
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -s 192.168.51.36 -p tcp --dport 8096 -j nixos-fw-accept
    '';

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    #caddy reverse-proxy for jellyfin here something like spirenix.services.caddy.<option (port, origin, etc).
  };
}
