{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf concatStringsSep length optionalString types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt enabled;
  cfg = config.${namespace}.virtualisation.kvm;
  user = config.${namespace}.user;
in
{
  options.${namespace}.virtualisation.kvm = with types; {
    enable = mkBoolOpt false "Enable KVM virtualisation";
    vfioIds = mkOpt (listOf str) [ ] "The hardware IDs to pass through to the VM";
    platform = mkOpt (enum [ "amd" "intel" ]) "intel" "The CPU platform of the host machine";
    # Use `machinectl` and then `machinectl status <name>` to get the unit "*.scope" of the VM
    machineUnits = mkOpt (listOf str) [ ] "The systemd *.scope units to wait for before starting Scream";
  };

  config = mkIf cfg.enable {
    boot = {
      kernelModules = [
        "kvm-${cfg.platform}"
				"i915"
        "vfio"
        "vfio_pci"
        "vfio_virqfd"
        "vfio_iommu_type1"
        "kvmfr"
        "vhost"
        "vhost_net"
        "vhost_vsock"
        "vhost_scsi"
      ];
      kernelParams = [
        "${cfg.platform}_iommu=on"
        "iommu=pt"
        "kvm.ignore_msrs=1"
        "vfio-pci.ids=${concatStringsSep "," cfg.vfioIds}"
      ];
      extraModprobeConfig = optionalString (length cfg.vfioIds > 0) ''
        softdep nvidia pre: vfio vfio-pci
        softdep nvidia* pre: vfio vfio-pci
        options vfio-pci ids=${concatStringsSep "," cfg.vfioIds}
				options kvm ignore_msrs=1
				options kvm report_ignored_msrs=0
        options kvmfr static_size_mb=64
      '';
      extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
    };

    services.qemuGuest.enable = true;

    services.udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="${user.name}", GROUP="qemu-libvirtd", MODE="0660"
    '';

    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0600 ${user.name} qemu-libvirtd -"
    ];

    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer

      spice
      spice-gtk
      spice-vdagent
      spice-protocol

      virglrenderer
      bridge-utils

      virtiofsd
      virtio-win
      win-spice

      quickemu
      # rustdesk # dont think this is used related to VMs
      # rustdesk-server # dont think this is ued related to VMs
    ];

    virtualisation = {
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        extraConfig = ''
          user = "${user.name}"
          group = "qemu-libvirtd"
        '';

        allowedBridges = [ "virbr0" "br0" ];

        onBoot = "ignore";
        onShutdown = "shutdown";

        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          ovmf = {
            enable = true;
            packages = [ pkgs.OVMFFull.fd ];
          };
          swtpm = enabled;
          verbatimConfig = ''
            namespaces = []
            user = "+${builtins.toString config.users.users.${user.name}.uid}"
            group = "qemu-libvirtd"
            cgroup_device_acl = [
              "/dev/null", "/dev/full", "/dev/zero",
              "/dev/random", "urandom",
              "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
              "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
              "/dev/kvmfr0"
            ]
          '';
        };
      };
    };

    spirenix = {
      user = {
        extraGroups = [
          "qemu-libvirtd"
          "libvirtd"
          "disk"
        ];
      };
    };
  };
}
