{ ... }:
{
  disko.devices = {
    disk = {
      primary = {
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
                passwordFile = "/tmp/disko-password"; # populated by bootstrap-nixos.sh
                # extraOpenArgs = [ ];
                settings = {
                  #		if you want to use the key for interactive login be sure there is no trailing newline; for example use `echo -n "password" > /tmp/secret.key`
                  allowDiscards = true;
                };
                content = {
                  type = "lvm_pv";
                  vg = "root-pool";
                };
              };
            };
          };
        };
      };
      data-hdd1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV2KBYD";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "data-crypt";
                passwordFile = "/tmp/disko-password"; # populated by bootstrap-nixos.sh
                settings = {
                  allowDiscards = true;
                };
                # Whether to add a boot.initrd.luks.devices entry for the this disk.
                # We only want to unlock cryptroot interactively.
                # You must have a /etc/crypttab entry set up to auto unlock the drive using a key on cryptroot (see /hosts/nixos/ghost/default.nix)
                initrdUnlock = true;
                content = {
                  type = "lvm_pv";
                  vg = "data-pool";
                };
              };
            };
          };
        };
      };
      data-hdd2-bak = {
        type = "disk";
        device = "/dev/disk/by-id/";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "bak-crypt";
                passwordFile = "/tmp/disko-password"; # populated by bootstrap-nixos.sh
                settings = {
                  allowDiscards = true;
                };
                # Whether to add a boot.initrd.luks.devices entry for the this disk.
                # We only want to unlock cryptroot interactively.
                # You must have a /etc/crypttab entry set up to auto unlock the drive using a key on cryptroot (see /hosts/nixos/ghost/default.nix)
                initrdUnlock = true;
                content = {
                  type = "lvm_pv";
                  vg = "backup-pool";
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
        };
      };
      data-pool = {
        type = "lvm_vg";
        lvs = {
          srv = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "server" "-f" ];
              subvolumes = {
                "/srv" = { mountpoint = "/srv"; mountOptions = [ "subvol=srv" "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
      backup-pool = {
        type = "lvm_vg";
        lvs = {
          bak = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "backups" "-f" ];
              subvolumes = {
                "/bak" = { mountpoint = "/bak"; mountOptions = [ "subvol=bak" "compress=zstd" "noatime" ]; };
              };
            };
          };
        };
      };
    };
  };
}
