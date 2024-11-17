{ lib
, pkgs
, host
, config
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [ ./hardware.nix ];

  networking.hostName = host;

	environment.systemPackages = with pkgs; [ firefox];

  services.pipewire = { enable = true; pulse.enable = true; };

  spirenix = {
    suites = {
      common = enabled;
      networking = enabled;
    };

    system = {
      disko = { enable = true; device = "/dev/nvme0n1"; };
      impermanence = enabled;
    };

    virtualisation = {
      podman = enabled;
      kvm = enabled;
    };
  };

  system.stateVersion = "24.05";
}
