{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-PNY_CS1311_120GB_SSD_PNY36162191600102D3B";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "root-crypt";
                # extraOpenArgs = [ ];
                settings = {
                  #		if you want to use the key for interactive login be sure there is no trailing newline; for example use `echo -n "password" > /tmp/secret.key`
                  # keyFile = "/tmp/root-crypt.key";
                  allowDiscards = true;
                };
                # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
                content = {
                  type = "lvm_pv";
                  vg = "root-pool";
                };
              };
            };
          };
        };
      };
      storageHDD1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Hitachi_HDS721010CLA632_JP2940J82WE5TV";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "data-crypt";
                # extraOpenArgs = [ ];
                settings = {
                  #		if you want to use the key for interactive login be sure there is no trailing newline; for example use `echo -n "password" > /tmp/secret.key`
                  # keyFile = "/tmp/data-crypt.key";
                  allowDiscards = true;
                };
                # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
                content = {
                  type = "lvm_pv";
                  vg = "data-pool";
                };
              };
            };
          };
        };
      };
    };

    # LVM definitions for volume groups
    lvm_vg = {
      root-pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "nixos" "-f" ];
              subvolumes = {
                "/root" = { mountpoint = "/"; };
                "/home" = { mountpoint = "/home"; mountOptions = [ "subvol=home" "compress=zstd" "noatime" ]; };
                "/persist" = { mountpoint = "/persist"; mountOptions = [ "subvol=persist" "compress=zstd" "noatime" ]; };
                "/nix" = { mountpoint = "/nix"; mountOptions = [ "subvol=nix" "compress=zstd" "noatime" ]; };
              };
            };
          };
          swap = {
            size = "16GB";
            content = {
              type = "swap";
            };
          };
        };
      };
      data-pool = {
        type = "lvm_vg";
        lvs = {
          srv = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "services" "-f" ];
              subvolumes = {
                "/srv" = { mountpoint = "/srv"; mountOptions = [ "subvol=srv" "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
    };
  };
}
