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
        wallpaper = "greens.oceanwaves-turquoise";
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

    services.karakeep.enable = lib.mkForce false;

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
  };

  system.stateVersion = "24.11";
}
