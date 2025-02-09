{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.media.readarr;
in {
  options.${namespace}.services.media.readarr = {
    enable = mkBoolOpt false "Enable Readarr";
    openFirewall = mkOpt types.bool false "Open firewall ports for Readarr.";
    dataDir = mkOpt types.str "/srv/apps/readarr" "Directory for Readarr data.";
  };

  config = mkIf cfg.enable {
    services.readarr = {
      enable = true;
      package = pkgs.readarr;
      user = "readarr";
      group = "readarr";
      inherit (cfg) openFirewall dataDir;
    };
  };
}