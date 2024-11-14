{ lib, pkgs, inputs, config, modulesPath, ... }:
let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    common-cpu-intel
    common-gpu-nvidia
    common-gpu-nvidia-pascal
    common-pc
    common-pc-ssd
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4"; # or your filesystem type
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
    "/mnt/data" = {
      device = "/dev/sda1";
      fsType = "auto";
      options = [ "rw" ];
    };
  };

  boot = {
    #boot config
    loader.grub = {
      enable = true;
      devices = [ "/dev/sda" ];
    };

    #kernel config
    kernelPackages = pkgs.linuxPackages_latest; #idk wtf this is
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelParams = [
      "drm_kms_helper.poll=0" #idk wtf this does
    ];

    initrd = {
      availableKernelModules = [
        #idk wtf any of this is for
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "xhci_pci"
      ];
      kernelModules = [ ];
    };
  };

  #other hardware
  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    firmware = with pkgs; [ linux-firmware ];

    bluetooth.enable = true;

    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
