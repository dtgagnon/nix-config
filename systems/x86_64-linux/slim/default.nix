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

  networking = {
    hostName = host;
    useDHCP = lib.mkDefault true;
  };

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
      # storage = {
      #   boot.enable = true;
      # };
    };

    security = {
      sudo = enabled;
      sops-nix = enabled;
    };

    system.enable = true; # gneral system config
    system.preservation = enabled;

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };
  };

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
      };
    };
    initrd = {
      availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_usb_sdmmc" ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  system.stateVersion = "24.11";
}
