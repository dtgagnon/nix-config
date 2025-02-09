{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.media.prowlarr;
in
{
  options.${namespace}.services.media.prowlarr = {
    enable = mkBoolOpt false "Enable Prowlarr";
    package = mkOpt types.package pkgs.prowlarr "Prowlarr package to use";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Prowlarr.";
  };

  config = mkIf cfg.enable {
    services.prowlarr = {
      enable = true;
      inherit (cfg) 
        package
        openFirewall
        ;
    };
  };
}