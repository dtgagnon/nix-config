{ lib
, host
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

  networking.hostName = host;

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  
  spirenix = {
    suites = {
      networking = enabled;
    };

    apps = {
      proton = enabled;
      proton-cloud = enabled;
      ea-games = enabled;
    };

    desktop = {
      fonts = enabled;
      hyprland = enabled;
      stylix = enabled;
    };

    hardware = {
      audio = enabled;
      graphics = { enable = true; manufacturer = "nvidia"; };
      storage.boot.enable = true;
    };

    security = {
      sudo = enabled;
      sops-nix = enabled;
    };

    system = {
      enable = true;
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
