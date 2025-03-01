#TODO: Update this file with my domain
{ lib
, NixVirt
, ...
} @ args:
let
  base = import ../../../nixos/nixvirt/base.nix args;
  windows_template = base.windows_template;
  pci_address = base.pci_address;
  usb_address = base.usb_address;
  drive_address = base.drive_address;
in
{
  definition =
    let
      Windows = windows_template {
        name = "windows11-GPU";
        uuid = "";
        memory = {
          count = 32;
          unit = "GiB";
        };
        nvram_path = /var/lib/libvirt/qemu/nvram/win11-GPU_VARS.fd;
        no_graphics = true;
        virtio_net = true;
      };
    in
    NixVirt.lib.domain.writeXML (
      Windows
      // {
        vcpu = {
          placement = "static";
          count = 12;
        };
        cpu = {
          mode = "host-passthrough";
          check = "full";
          migratable = false;
          topology = {
            sockets = 1;
            dies = 1;
            cores = 6;
            threads = 2;
          };
          cache = {
            mode = "passthrough";
          };
          # feature = {
          #   policy = "require";
          #   name = "topoext";
          # };
        };
        iothreads = {
          count = 1;
        };
        cputune = {
          vcpupin =
            builtins.map
              (x: {
                vcpu = x;
                cpuset = toString x;
              })
              (lib.lists.range 0 5)
            ++ builtins.map
              (x: {
                vcpu = x;
                cpuset = toString (x + 8);
              })
              (lib.lists.range 8 13);

          emulatorpin = {
            cpuset = "0,16";
          };
          iothreadpin = {
            iothread = 1;
            cpuset = "0,16";
          };
        };
        memoryBacking = {
          hugepages = { };
        };
        clock =
          Windows.clock
          // {
            timer =
              lib.lists.remove
                {
                  name = "hpet";
                  present = false;
                }
                Windows.clock.timer
              ++ [
                {
                  name = "hpet";
                  present = true;
                }
              ];
          };
        os =
          Windows.os
          // {
            boot = null;
            bootmenu = { enable = false; };
          };
        devices =
          Windows.devices
          // {
            disk =
              if builtins.isNull Windows.devices.disk
              then [ ]
              else
                Windows.devices.disk
                ++ [
                  # Games.qcow2
                  {
                    type = "volume";
                    device = "disk";
                    driver = {
                      name = "qemu";
                      type = "qcow2";
                      cache = "none";
                      discard = "unmap";
                    };
                    source = {
                      pool = "DiskPool";
                      volume = "Games.qcow2";
                    };
                    target = {
                      dev = "vdd";
                      bus = "virtio";
                    };
                  }

                  # Data.qcow2
                  {
                    type = "volume";
                    device = "disk";
                    driver = {
                      name = "qemu";
                      type = "qcow2";
                      cache = "none";
                      discard = "unmap";
                    };
                    source = {
                      pool = "DiskPool";
                      volume = "Data.qcow2";
                    };
                    target = {
                      dev = "vde";
                      bus = "virtio";
                    };
                  }
                ];
            tpm = {
              model = "tpm-tis";
              backend = {
                type = "passthrough";
                device = {
                  path = "/dev/tpm0";
                };
              };
            };
            graphics = {
              type = "spice";
              autoport = true;
              listen = { type = "address"; };
              image = { compression = false; };
              gl = { enable = false; };
            };
            hostdev = [
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                # RTX 4090 01:00.0
                source = { address = pci_address 1 0 0; };
                address = pci_address 5 0 0 // { multifunction = true; };
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = { address = pci_address 1 0 1; };
                # RTX 4090 01:00.1
                address = pci_address 5 0 1 // { multifunction = true; };
              }
              #{
              #  type = "pci";
              #  mode = "subsystem";
              #  managed = true;
              #  source = {address = pci_address 69 0 3;};
              #  # Backend USB Controller 45:00.3
              #  address = pci_address 7 0 0;
              #}
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = { address = pci_address 2 0 0; };
                # Intel SSD 760p 02:00.0
                address = pci_address 8 0 0;
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = { address = pci_address 7 0 3; };
                # Backend USB Controller 07:00.3
                address = pci_address 9 0 0;
              }
            ];
            interface = [
              {
                type = "bridge";
                model = { type = "virtio"; };
                source = { bridge = "br0"; };
              }
            ];
          };
        qemu-commandline = {
          arg = [
            { value = "-overcommit"; }
            { value = "cpu-pm=off"; }
            { value = "-fw_cfg"; }
            { value = "opt/ovmf/X-PciMmio64Mb,string=65536"; }
            { value = "-device"; }
            { value = "{\"driver\":\"ivshmem-plain\",\"id\":\"shmem0\",\"memdev\":\"looking-glass\"}"; }
            { value = "-object"; }
            { value = "{\"qom-type\":\"memory-backend-file\",\"id\":\"looking-glass\",\"mem-path\":\"/dev/kvmfr0\",\"size\":268435456,\"share\":true}"; }
          ];
        };
        # qemu-override = {
        #   device = {
        #     alias = "hostdev0";
        #     frontend = {
        #       property = {
        #         name = "x-vga";
        #         type = "bool";
        #         value = "true";
        #       };
        #     };
        #   };
        # };
      }
    );
}
