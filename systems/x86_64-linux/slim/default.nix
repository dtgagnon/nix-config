{ lib
, host
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [
    ./disk-config.nix
    ./hardware.nix
  ];

  networking.hostName = host;

  spirenix = {
    suites.networking = enabled;

    desktop = {
      hyprland = enabled;
      fonts = enabled;
      stylix = enabled;
    };

    hardware = {
      audio = enabled;
      keyboard = enabled; # xkb stuff
      storage = {
        boot.enable = true;
      };
    };

    security = {
      sudo = enabled;
      sops-nix = enabled;
    };

    system.enable = true;

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };

    # topology.self.hardware.info = "DG-PC";
  };

  system.stateVersion = "24.11";
}
