{
  lib,
  pkgs,
  config,
  namespace,
  ...
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
    environment.systemPackages = with pkgs; [
      wget
      curl
    ];

    spirenix = {
      security.vpn = enabled;
      services = {
        openssh = enabled;
        tailscale = enabled;
      };
    };
  };
}