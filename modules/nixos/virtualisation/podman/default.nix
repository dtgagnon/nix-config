{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.virtualisation.podman;
in
{
  options.${namespace}.virtualisation.podman = {
    enable = mkBoolOpt false "Whether or not to enable Podman.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.podman-compose ];

    spirenix.user.home.extraOptions = {
      home.shellAliases = {
        "docker-compose" = "podman-compose";
      };
    };

    virtualisation = {
      podman = {
        enable = cfg.enable;
        dockerCompat = true;
      };
    };
  };
}
