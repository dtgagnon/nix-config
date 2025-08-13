{ lib
, host
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.networking;
in
{
  options.${namespace}.suites.networking = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = host;
      # networkmanager.enable = true;
      # useDHCP = lib.mkDefault true;
    };

    spirenix = {
      security.vpn = enabled;
      services = {
        tailscale = enabled;
      };
    };
  };
}
