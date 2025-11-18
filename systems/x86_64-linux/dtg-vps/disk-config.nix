# Disk configuration for Digital Ocean VPS - designed for nixos-anywhere deployment
# Digital Ocean droplets use virtio disks (/dev/vda)
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda"; # Digital Ocean uses virtio disks
        content = {
          type = "gpt";
          partitions = {
            # BIOS boot partition for legacy boot compatibility
            MBR = {
              priority = 0;
              size = "1M";
              type = "EF02";
            };
            # EFI system partition
            ESP = {
              priority = 1;
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            # Swap partition (4GB for typical VPS)
            swap = {
              priority = 2;
              size = "4G";
              content = {
                type = "swap";
                randomEncryption = true; # Encrypt swap on each boot
              };
            };
            # Root partition
            root = {
              priority = 3;
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Force overwrite
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # Reserve space for nginx logs and ACME certs
                  "/var-lib-acme" = {
                    mountpoint = "/var/lib/acme";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
