{
  lib,
  config,
  inputs,
  modulesPath,
  ...
}:
let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    common-cpu-intel
    common-pc
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
}
