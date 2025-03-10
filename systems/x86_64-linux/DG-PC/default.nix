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
    ./hardware.nix
    ./disk-config.nix
  ];

  networking.hostName = host;

  spirenix = {
    suites = {
      gaming = enabled;
      networking = enabled;
    };

    apps = {
      proton = enabled;
      proton-cloud = enabled;
    };

    desktop = {
      fonts = enabled;
      hyprland = enabled;
      stylix = enabled;
    };

    hardware = {
      audio = enabled;
      gpu = { enable = true; iGPU = "intel"; };
      storage = {
        boot.enable = true;
      };
    };

    security = {
      sudo = enabled;
      sops-nix = enabled;
    };

    services = {
      davfs = enabled;
      openssh.manage-other-hosts = false;
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

    # topology.self.hardware.info = "DG-PC";

    virtualisation = {
      podman = enabled;
      kvm = {
        enable = true;
        vfio = {
          enable = true; #config'd for looking glass
          blacklistNvidia = true;
          vfioIds = [
            "10de:2684" #RTX4090 ID
            "10de:22ba" #RTX4090 audio controller ID
          ];
        };
      };
    };
  };
  system.stateVersion = "24.11";
}
