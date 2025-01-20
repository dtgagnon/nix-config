{ ... }:
{
  disko.devices = {
    disk = {
      primary = {
        type = "disk";
        device = "/dev/disk/by-id/ata-SanDisk_SD5SE2128G1002E_130471400430";
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
                askPassword = true;
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
    };
  };
}
