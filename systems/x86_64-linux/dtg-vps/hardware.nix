{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    # Digital Ocean specific optimizations
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  # Boot configuration for Digital Ocean
  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true; # Digital Ocean requires this
        device = "nodev";
      };
    };

    # Enable serial console for Digital Ocean console access
    kernelParams = [ "console=ttyS0" "console=tty1" ];

    # Clean /tmp on boot
    tmp.cleanOnBoot = true;

    # Kernel modules for Digital Ocean
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
  };

  # Networking
  networking = {
    useDHCP = true;
    useNetworkd = true;
  };

  # Digital Ocean uses virtio for everything
  hardware.enableRedistributableFirmware = false;
}
