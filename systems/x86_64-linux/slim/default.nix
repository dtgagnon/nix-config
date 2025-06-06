{ lib
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

  fileSystems."/boot".options = [ "umask=0077" ];
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = lib.mkDefault 3;
        consoleMode = lib.mkDefault "max";
        editor = false;
      };
    };
    initrd = {
      systemd.enable = true;
      systemd.emergencyAccess = true;
      luks.forceLuksSupportInInitrd = true;
      availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_usb_sdmmc" ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  spirenix = {
    suites.networking = enabled;

    desktop = {
      gnome = enabled;
      fonts = enabled;
      stylix = {
        enable = true;
        wallpaper = "catppuccin.skull-popcolor";
      };
    };

    hardware = {
      audio = enabled;
      keyboard = enabled; # xkb stuff
      laptop = enabled; # battery, lid, etc.
    };

    security = {
      pam = enabled;
      sudo = enabled;
      sops-nix = enabled;
    };

    services = { };

    system.enable = true; # gneral system config
    system.preservation = enabled;

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };
  };
  system.stateVersion = "24.11";
}
