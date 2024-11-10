{
	fileSystems."/" = {
  device = "/dev/disk/by-uuid/your-root-uuid";
  fsType = "ext4"; # or your filesystem type
};
boot.loader.grub.enable = true;
boot.loader.grub.devices = [ "/dev/sda" ];
}
