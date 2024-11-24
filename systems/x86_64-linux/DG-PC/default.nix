{
  lib,
  host,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [ ./hardware.nix ];

  networking.hostName = host;

  spirenix = {
    suites.networking = enabled;

    desktop = {
      gnome = enabled;
      # hyprland = enabled;
      stylix = enabled;
    };

    hardware = {
      audio = enabled;
      nvidia = enabled;
    };

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
      disko = {
        enable = true;
        device = "/dev/nvme0n1";
      };
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

  system.stateVersion = "24.05";
}
