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
      pam = enabled;
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

  users.users.root = {
    password = "1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9zKXOt7YQW0NK0+GsUQh4cgmcLyurpeTzYXMYysUH1 user=dtgagnon"
    ];
  };

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

  system.stateVersion = "24.11";
}
