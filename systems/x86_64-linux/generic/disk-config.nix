{
  lib,
  ... 
}:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/sda";
      type = "disk"
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "500M";
            type = "EF00";
            mountpoint = "/boot";
          };
          root = {
            name = "root";
            size = "100%";
            contents = {
              type = "8309";
              encrypted = {
                enable = true;
                keyFile = "/root/cryptkeyfile";
                lvm = {
                  enable = true;
                  name = "vg";
                  volumes = {
                    root = {
                      size = "100%FREE";
                      mountpoint = "/";
                    };
                  };
                };
              };
            };
          };
        };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              mountpoint = "/";
              mountOptions = [ "defaults" ];
            };
          };
        }
      };
    }
  };
}