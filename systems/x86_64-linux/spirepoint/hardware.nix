{ lib
, config
, inputs
, modulesPath
, ...
}:
let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    common-cpu-intel
    common-pc
    common-pc-ssd
  ];

  spirenix.hardware = {
    audio.enable = true;
    gpu = {
      enable = true;
      iGPU = {
        isPrimary = false;
        mfg = "intel";
        deviceIds = [ "" ];
        busId = "";
      };
      dGPU = {
        mfg = "nvidia";
        deviceIds = [ "10de:1c02" "10de:10f1" ];
        busId = "";
      };
      nvidiaChannel = "stable";
      nvidiaPrime = false;
    };
    storage.boot = {
      ## Needed?
      enable = true;
      bootloader.configLimit = 20;
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

  swapDevices = [{ device = "/var/swapfile"; size = 16384; }];

  #other hardware
  hardware = {
    #   enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    bluetooth.enable = true;

    # logitech.wireless = {
    #   enable = true;
    #   enableGraphical = true;
    # };
  };
}

# Hardware components
# │ MB: Z170A GAMING M5 (MS-7977) (1.0)
# │  : Intel(R) Core(TM) i7-6700K (8) @ 4.20 GHz
# │ 󰍛 : NVIDIA GeForce GTX 1060 3GB [Discrete]
# │ 󰍛 : Intel HD Graphics 530 @ 1.15 GHz [Integrated]
# │ 󰑭 : 649.11 MiB / 15.51 GiB (4%)
