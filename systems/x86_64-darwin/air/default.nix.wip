{ lib
, host
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  # imports = [
  #   ./hardware.nix
  #   ./disk-config.nix
  # ];

  networking.hostName = host;

  spirenix = {
    suites = {
      networking = enabled;
    };

    # desktop = {
    #   fonts = enabled;
    #   # stylix = enabled;
    # };

    # security = {
    #   sudo = enabled;
    #   sops-nix = enabled;
    # };

    system = {
      enable = true;
    };

    tools = {
      # comma = enabled;
      general = enabled;
      monitoring = enabled;
      # nix-ld = enabled;
    };

    # virtualisation = {
    #   podman = enabled;
    # };
  };

  system.stateVersion = "5";
}
