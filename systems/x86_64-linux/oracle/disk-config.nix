# Disk configuration for Oracle VPS - designed for nixos-anywhere deployment
# No LUKS encryption on root to allow unattended remote deployment
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda"; # Adjust based on Oracle VPS disk (typically /dev/sda)
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "4G"; # Adjust based on VPS RAM
              content = {
                type = "swap";
                randomEncryption = true; # Encrypt swap on each boot
              };
            };
            root = {
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
                  "/var-lib-coolify" = {
                    mountpoint = "/var/lib/coolify";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/var-lib-docker" = {
                    mountpoint = "/var/lib/docker";
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
