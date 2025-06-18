{ lib
, config
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [
    ./hardware.nix
    ./disk-config.nix
  ];

  spirenix = {
    suites = {
      arrs = enabled;
      gaming = enabled;
      networking = enabled;
      self-host = enabled;
    };

    apps = {
      proton = enabled;
      proton-cloud = enabled;
    };

    desktop = {
      fonts = enabled;
      gnome = enabled;
      stylix = {
        enable = true;
        wallpaper = "hazy-purple-orange-sunset-palmtrees";
      };
    };

    security = {
      pam = enabled;
      sudo = enabled;
      sops-nix = {
        enable = true;
        targetHost = "spirepoint";
      };
    };

    system = {
      enable = true;
      preservation = enabled;
    };

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };

    virtualisation.kvm.enable = false;
  };

  system.stateVersion = "24.11";
}
