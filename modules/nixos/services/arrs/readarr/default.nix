{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.arrs.readarr;
in
{
  options.${namespace}.services.arrs.readarr = {
    enable = mkBoolOpt false "Enable Readarr";
    openFirewall = mkOpt types.bool false "Open firewall ports for Readarr.";
    dataDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/readarr" "Directory for Readarr data.";
  };

  config = mkIf cfg.enable {
    services.readarr = {
      enable = true;
      package = pkgs.bookshelf;
      user = "readarr";
      group = "media";
      inherit (cfg) openFirewall dataDir;
    };
  };
}
