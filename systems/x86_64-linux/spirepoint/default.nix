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

    hardware = {
      audio = enabled;
      gpu = { enable = true; dGPU = "nvidia"; };
      storage.boot = {
        enable = true;
        kernel.params = [
          "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
          "systemd.show_status=true"
          "systemd.log_target=console"
          "systemd.journald.forward_to_console=1"
        ];
        kernel.initrd = {
          forceLuks = true;
          availableKernelModules = [
            "xhci_pci"
            "ehci_pci"
            "ahci"
            "sd_mod"
            "rtsx_usb_sdmmc"
          ];
        };
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

    #TODO: Enable again when VMs are declared
    virtualisation = {
      podman = enabled;
      #   kvm = {
      #     enable = true;
      #     vfio = {
      #       enable = true;
      #       blacklistNvidia = true;
      #       vfioIds = [
      #         "10de:1c02" #GTX1060 ID
      #         "10de:10f1" #GTX1060 audio controller ID
      #       ];
      #     };
      #   };
    };
  };

  system.stateVersion = "24.11";
}
