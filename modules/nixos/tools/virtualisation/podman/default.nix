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
    spirenix.user.home.extraOptions = {
      home.packages = with pkgs; [
        arion
        podman
        podman-compose
        podman-tui
        amazon-ecr-credential-helper
      ];
      home.shellAliases = {
        "docker-compose" = "podman-compose";
      };
    };

    virtualisation.podman = {
      enable = cfg.enable;
      dockerSocket.enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}