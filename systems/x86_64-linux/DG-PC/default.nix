{
  lib,
  host,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  imports = [ ./hardware.nix ];

  networking.hostName = host;

  spirenix = {
    suites.networking = enabled;

    desktop = {
      gnome = disabled;
      fonts = enabled;
      hyprland = enabled;
      stylix = disabled;
    };

    hardware = {
      audio = enabled;
      keyboard = enabled; # xkb stuff
      nvidia = enabled;
      storage = {
        boot.enable = true;
        disko = {
          enable = true;
          device = "/dev/nvme0n1";
        };
      };
    };

    security = {
      sudo = enabled;
      sops-nix = enabled;
    };

    services = {
      openssh = enabled;
    };

    system = {
      enable = true;
      impermanence = enabled;
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
