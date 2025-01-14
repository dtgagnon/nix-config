{ lib
, host
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  imports = [
    ./hardware.nix
    ./disk-config.nix
  ];

  networking.hostName = host;

  spirenix = {
    suites = {
      networking = enabled;
    };

    desktop = {
      fonts = enabled;
      gnome = enabled;
    };

    hardware = {
      audio = enabled;
      graphics = { enable = true; manufacturer = "nvidia"; };
      storage = {
        boot.enable = true;
      };
    };

    security = {
      sudo = enabled;
      sops-nix = enabled;
    };

    services = {
      openssh = enabled;
      tailscale = enabled;
    };

    system = {
      enable = true;
      # impermanence = enabled;
    };

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };

    # topology.self.hardware.info = "DG-PC";

    virtualisation = {
      podman = enabled;
      kvm = enabled;
    };
  };

  system.stateVersion = "24.11";
}
