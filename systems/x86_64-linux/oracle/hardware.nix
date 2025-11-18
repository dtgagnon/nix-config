{ lib, config, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  spirenix.hardware.storage.boot = {
    enable = true;
    bootloader.configLimit = 10;
    kernel.initrd = {
      forceLuks = false;
      availableKernelModules = [
        "xhci_pci"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
    };
  };

  # Oracle VPS typically uses virtio for networking
  boot.kernelModules = [ "virtio_net" ];

  # Enable firmware updates
  hardware.enableRedistributableFirmware = true;

  # Swap is configured in disk-config.nix (4GB with random encryption)
  swapDevices = [ ];

  # Networking
  networking = {
    useDHCP = lib.mkDefault true;
    hostName = "oracle";
  };
}
