{ pkgs
, ...
}:
{
  # Set the qemu namespace required for the custom commandline
  # attrs."xmlns:qemu" = "http://libvirt.org/schemas/domain/qemu/1.0";

  type = "kvm";
  name = "win11-GPU";
  uuid = "456cf1dd-e827-4162-b1d9-14dd038f963d";

  metadata.libosinfo = {
    "xmlns:libosinfo" = "http://libosinfo.org/xmlns/libvirt/domain/1.0";
    os.id = "http://microsoft.com/win/11";
  };

  memory = { count = 32; unit = "GiB"; }; # 32804864 KiB

  memoryBacking = {
    source.type = "memfd";
    access.mode = "shared";
  };

  vcpu = { count = 12; placement = "static"; };

  cputune.vcpupin = [
    { vcpu = 0; cpuset = "4"; }
    { vcpu = 1; cpuset = "5"; }
    { vcpu = 2; cpuset = "6"; }
    { vcpu = 3; cpuset = "7"; }
    { vcpu = 4; cpuset = "8"; }
    { vcpu = 5; cpuset = "9"; }
    { vcpu = 6; cpuset = "10"; }
    { vcpu = 7; cpuset = "11"; }
    { vcpu = 8; cpuset = "12"; }
    { vcpu = 9; cpuset = "13"; }
    { vcpu = 10; cpuset = "14"; }
    { vcpu = 11; cpuset = "15"; }
  ];

  os = {
    attrs.firmware = "efi";
    type = {
      attrs = { arch = "x86_64"; machine = "pc-q35-9.2"; };
      content = "hvm";
    };
    firmware.feature = [
      { attrs = { enabled = "no"; name = "enrolled-keys"; }; }
      { attrs = { enabled = "yes"; name = "secure-boot"; }; }
    ];
    # Using pkgs.OVMFFull.fd will get the secure boot variant.
    # The path will be resolved by Nix at build time.
    loader = {
      attrs = { readonly = "yes"; secure = "yes"; type = "pflash"; };
      content = "${pkgs.OVMFFull.fd}/share/qemu/edk2-x86_64-secure-code.fd";
    };
    nvram = {
      attrs.template = "${pkgs.OVMFFull.fd}/share/qemu/edk2-i386-vars.fd";
      content = "/var/lib/libvirt/qemu/nvram/win11-GPU_VARS.fd";
    };
    boot = [{ attrs.dev = "hd"; }];
    smbios.mode = "host";
  };

  features = {
    acpi = { };
    apic = { };
    hyperv = {
      mode = "custom";
      relaxed.state = "on";
      vapic.state = "on";
      spinlocks = { state = "on"; retries = "8191"; };
      vpindex.state = "on";
      runtime.state = "on";
      synic.state = "on";
      stimer.state = "on";
      vendor_id = { state = "on"; value = "nix-community"; }; # Use your preferred vendor_id
      frequencies.state = "on";
      tlbflush.state = "on";
      ipi.state = "on";
      evmcs.state = "on";
      avic.state = "on";
    };
    kvm.hidden.state = "on";
    vmport.state = "off";
    smm.state = "on";
  };

  cpu = {
    mode = "host-passthrough";
    attrs = { check = "none"; migratable = "on"; };
    topology = { sockets = "1"; dies = "1"; clusters = "1"; cores = "6"; threads = "2"; };
    cache.mode = "passthrough";
    maxphysaddr.mode = "emulate";
  };

  clock = {
    offset = "localtime";
    timer = [
      { name = "rtc"; tickpolicy = "catchup"; }
      { name = "pit"; tickpolicy = "delay"; }
      { name = "hpet"; present = "no"; }
      { name = "hypervclock"; present = "yes"; }
    ];
  };

  on_poweroff = "destroy";
  on_reboot = "restart";
  on_crash = "destroy";

  pm = {
    suspend-to-mem.enabled = "no";
    suspend-to-disk.enabled = "no";
  };

  devices = {
    disk = [
      {
        attrs = { type = "file"; device = "disk"; };
        driver = { name = "qemu"; type = "raw"; };
        source.file = "/var/lib/libvirt/images/win11-GPU.img"; # Main OS disk
        target = { dev = "vda"; bus = "virtio"; };
        address = { type = "pci"; domain = "0x0000"; bus = "0x04"; slot = "0x00"; function = "0x0"; };
      }
      {
        attrs = { type = "file"; device = "cdrom"; };
        driver = { name = "qemu"; type = "raw"; };
        source.file = "/var/lib/libvirt/isos/virtio-win-0.1.271.iso"; # VirtIO drivers
        target = { dev = "sda"; bus = "sata"; };
        readonly = { };
        address = { type = "drive"; controller = "0"; bus = "0"; target = "0"; unit = "0"; };
      }
    ];
    controller = [
      { type = "usb"; index = "0"; model = "qemu-xhci"; ports = "15"; address = { type = "pci"; domain = "0x0000"; bus = "0x02"; slot = "0x00"; function = "0x0"; }; }
      { type = "pci"; index = "0"; model = "pcie-root"; }
      { type = "pci"; index = "1"; model = "pcie-root-port"; target = { chassis = "1"; port = "0x10"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x02"; function = "0x0"; multifunction = "on"; }; }
      { type = "pci"; index = "2"; model = "pcie-root-port"; target = { chassis = "2"; port = "0x11"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x02"; function = "0x1"; }; }
      { type = "pci"; index = "3"; model = "pcie-root-port"; target = { chassis = "3"; port = "0x12"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x02"; function = "0x2"; }; }
      { type = "pci"; index = "4"; model = "pcie-root-port"; target = { chassis = "4"; port = "0x13"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x02"; function = "0x3"; }; }
      { type = "pci"; index = "5"; model = "pcie-root-port"; target = { chassis = "5"; port = "0x14"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x02"; function = "0x4"; }; }
      { type = "pci"; index = "6"; model = "pcie-root-port"; target = { chassis = "6"; port = "0x15"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x02"; function = "0x5"; }; }
      { type = "pci"; index = "7"; model = "pcie-root-port"; target = { chassis = "7"; port = "0x16"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x02"; function = "0x6"; }; }
      { type = "pci"; index = "8"; model = "pcie-root-port"; target = { chassis = "8"; port = "0x17"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x02"; function = "0x7"; }; }
      { type = "pci"; index = "9"; model = "pcie-root-port"; target = { chassis = "9"; port = "0x18"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x03"; function = "0x0"; multifunction = "on"; }; }
      { type = "pci"; index = "10"; model = "pcie-root-port"; target = { chassis = "10"; port = "0x19"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x03"; function = "0x1"; }; }
      { type = "pci"; index = "11"; model = "pcie-root-port"; target = { chassis = "11"; port = "0x1a"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x03"; function = "0x2"; }; }
      { type = "pci"; index = "12"; model = "pcie-root-port"; target = { chassis = "12"; port = "0x1b"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x03"; function = "0x3"; }; }
      { type = "pci"; index = "13"; model = "pcie-root-port"; target = { chassis = "13"; port = "0x1c"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x03"; function = "0x4"; }; }
      { type = "pci"; index = "14"; model = "pcie-root-port"; target = { chassis = "14"; port = "0x1d"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x03"; function = "0x5"; }; }
      { type = "pci"; index = "15"; model = "pcie-root-port"; target = { chassis = "15"; port = "0x1e"; }; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x03"; function = "0x6"; }; }
      { type = "sata"; index = "0"; address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x1f"; function = "0x2"; }; }
      { type = "virtio-serial"; index = "0"; address = { type = "pci"; domain = "0x0000"; bus = "0x03"; slot = "0x00"; function = "0x0"; }; }
    ];

    filesystem = {
      attrs = { type = "mount"; accessmode = "passthrough"; };
      driver.type = "virtiofs";
      source.dir = "/home/dtgagnon/myVMs/vm_share"; # Make sure this path is correct for your system
      target.dir = "nix_share";
      address = { type = "pci"; domain = "0x0000"; bus = "0x05"; slot = "0x00"; function = "0x0"; };
    };

    interface = {
      attrs = { type = "network"; };
      mac.address = "52:54:00:68:e5:87";
      source.network = "default";
      model.type = "virtio";
      address = { type = "pci"; domain = "0x0000"; bus = "0x01"; slot = "0x00"; function = "0x0"; };
    };

    input = [
      { type = "mouse"; bus = "virtio"; address = { type = "pci"; domain = "0x0000"; bus = "0x0a"; slot = "0x00"; function = "0x0"; }; }
      { type = "keyboard"; bus = "virtio"; address = { type = "pci"; domain = "0x0000"; bus = "0x09"; slot = "0x00"; function = "0x0"; }; }
      { type = "mouse"; bus = "ps2"; }
      { type = "keyboard"; bus = "ps2"; }
    ];

    tpm = {
      attrs.model = "tpm-crb";
      backend = {
        attrs = { type = "emulator"; version = "2.0"; };
        profile.name = "default-v1";
      };
    };

    graphics = {
      attrs = { type = "spice"; autoport = "no"; }; # Note: XML dump has port="-1" which often means autoport is desired. Set to 'yes' if you have issues.
      listen.type = "address";
      image.compression = "off";
    };

    video.model = {
      type = "vga";
      vram = "16384";
      heads = "1";
      primary = "yes";
    };
    video.address = { type = "pci"; domain = "0x0000"; bus = "0x00"; slot = "0x01"; function = "0x0"; };

    hostdev = [
      # GPU Video
      {
        attrs = { mode = "subsystem"; type = "pci"; managed = "yes"; };
        source.address = { domain = "0x0000"; bus = "0x01"; slot = "0x00"; function = "0x0"; };
        rom.attrs = { bar = "on"; };
        address = { type = "pci"; domain = "0x0000"; bus = "0x06"; slot = "0x00"; function = "0x0"; };
      }
      # GPU Audio
      {
        attrs = { mode = "subsystem"; type = "pci"; managed = "yes"; };
        source.address = { domain = "0x0000"; bus = "0x01"; slot = "0x00"; function = "0x1"; };
        rom.attrs = { bar = "on"; };
        address = { type = "pci"; domain = "0x0000"; bus = "0x07"; slot = "0x00"; function = "0x0"; };
      }
      # USB Device 1
      {
        attrs = { mode = "subsystem"; type = "usb"; managed = "yes"; };
        source = {
          vendor.id = "0x256f";
          product.id = "0xc635";
        };
        address = { type = "usb"; bus = "0"; port = "1"; };
      }
      # USB Device 2
      {
        attrs = { mode = "subsystem"; type = "usb"; managed = "yes"; };
        source = {
          vendor.id = "0x2207";
          product.id = "0x110c";
        };
        address = { type = "usb"; bus = "0"; port = "5"; };
      }
    ];

    memballoon.model = "none";
  };

  # Custom QEMU commandline arguments for Looking Glass
  "qemu-commandline".arg = [
    { value = "-device"; }
    { value = "{\"driver\":\"ivshmem-plain\",\"id\":\"shmem0\",\"memdev\":\"looking-glass\"}"; }
    { value = "-object"; }
    # NOTE: XML size is 67108864 (64MiB). This should match your kvmfr module setting.
    { value = "{\"qom-type\":\"memory-backend-file\",\"id\":\"looking-glass\",\"mem-path\":\"/dev/kvmfr0\",\"size\":67108864,\"share\":true}"; }
    { value = "-fw_cfg"; }
    { value = "opt/ovmf/X-PciMmio64Mb,string=65536"; }
  ];
}
