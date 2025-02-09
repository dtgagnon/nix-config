{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.qbittorrent;
in
{
  options.${namespace}.apps.qbittorrent = {
    enable = mkBoolOpt false "Enable qBittorrent";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ 
      pkgs.qbittorrent
    ];
  };
}