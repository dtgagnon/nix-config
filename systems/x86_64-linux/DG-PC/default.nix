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
      nvidia = enabled;
      storage = {
        boot.enable = true;
        disko = { enable = true; device = "/dev/nvme0n1"; };
      };
    };

    security = {
      sudo = enabled;
      sops-nix = enabled;
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
