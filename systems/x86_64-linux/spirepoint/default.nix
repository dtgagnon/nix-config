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
    modesetting.enable = lib.mkForce true;
    powerManagement.enable = lib.mkForce true;
    powerManagement.finegrained = lib.mkForce false;
    open = lib.mkForce false;
    package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.stable;
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
      systemd.emergencyAccess = true; # don't need to enter password in emergency mode
      luks.forceLuksSupportInInitrd = true;
      availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_usb_sdmmc" ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelParams = [
      "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
      "systemd.show_status=true"
      "systemd.log_target=console"
      "systemd.journald.forward_to_console=1"
    ];
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = lib.mkForce "yes";
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
  };

  security.pam = {
    rssh.enable = true;
    services.sudo = {
      rssh = true;
    };
  };

  users.users.root = {
    password = "1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9zKXOt7YQW0NK0+GsUQh4cgmcLyurpeTzYXMYysUH1 user=dtgagnon"
    ]; # Replace "KEY" with your public key
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

    # services = {
    #   jellyfin = enabled;
    #   plane-nix = enabled;
    # };

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
