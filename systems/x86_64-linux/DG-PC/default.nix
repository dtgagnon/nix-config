{ lib
, host
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [ ./hardware.nix ];

  networking.hostName = host;

  spirenix = {
    suites.networking = enabled;

    apps = {
      firefox = enabled;
    };

    desktop.gnome = enabled;

    hardware = {
      audio = enabled;
      nvidia = enabled;
    };

    nix = enabled;

    security = {
      sudo = enabled;
      sops-nix = enabled;
    };

    services = {
      openssh = enabled;
    };

    system = {
      boot = enabled;
      fonts = enabled;
      locale = enabled;
      network = enabled;
      time = enabled;
      xkb = enabled;
      disko = { enable = true; device = "/dev/nvme0n1"; };
      impermanence = enabled;
    };

    tools = {
      general = enabled;
      nix-ld = enabled;
    };

    virtualisation = {
      podman = enabled;
      kvm = enabled;
    };
  };

  system.stateVersion = "24.05";
}
