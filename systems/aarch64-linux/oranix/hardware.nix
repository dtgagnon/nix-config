{
  lib,
  config,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  spirenix.hardware.storage.boot = {
    enable = true;
    bootloader.configLimit = 3;
    kernel.params = [
      "systemd.log_target=console"
      "systemd.show_status=true"
      "systemd.journald.forward_to_console=1"
    ];
    kernel.initrd = {
      forceLuks = false;
      availableKernelModules = [
        "virtio_pci"
        "virtio_scsi"
        "virtio_blk"
        "virtio_net"
        "sd_mod"
      ];
    };
  };

  # Oracle Ampere A1 uses virtio for networking and block devices
  boot.kernelModules = [ "virtio_net" "virtio_blk" ];

  # Enable firmware updates
  hardware.enableRedistributableFirmware = true;

  # Swap is configured in disk-config.nix (4GB with random encryption)
  swapDevices = [ ];
}
