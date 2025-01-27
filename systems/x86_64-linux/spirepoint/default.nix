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

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = lib.mkForce false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  spirenix = {
    suites = {
      gaming = enabled;
      networking = enabled;
    };

    apps = {
      proton = enabled;
      proton-cloud = enabled;
      ea-games = enabled;
    };

    desktop = {
      fonts = enabled;
      gnome = enabled;
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

    services = {
      jellyfin = enabled;
      plane-nix = enabled;
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
