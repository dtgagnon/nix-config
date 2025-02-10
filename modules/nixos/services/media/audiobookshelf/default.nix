{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.media.audiobookshelf;
in
{
  options.${namespace}.services.media.audiobookshelf = {
    enable = mkBoolOpt false "Enable Audio Bookshelf";
    host = mkOpt types.str "0.0.0.0" "IPv4 address the service binds to";
    port = mkOpt types.int 8000 "Port to run Audio Bookshelf on";
    openFirewall = mkBoolOpt false "Open firewall ports for Audio Bookshelf.";
    dataDir = mkOpt types.str "/srv/apps/audiobookshelf" "Directory for Audio Bookshelf data";
  };

  config = mkIf cfg.enable {
    services.audiobookshelf = {
      enable = true;
      package = pkgs.audiobookshelf;
      user = "audiobookshelf";
      group = "media";
      inherit (cfg)
        host
        port
        openFirewall
        dataDir
        ;
    };
  };
}
