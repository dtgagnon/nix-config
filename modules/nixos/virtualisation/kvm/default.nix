{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt enabled;
  cfg = config.${namespace}.virtualisation.kvm;
  user = config.${namespace}.user;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.virtualisation.kvm = with types; {
    enable = mkBoolOpt false "Enable KVM virtualisation";
    platform = mkOpt (enum [ "amd" "intel" ]) "intel" "The CPU platform of the host machine";
    # Use `machinectl` and then `machinectl status <name>` to get the unit "*.scope" of the VM
    machineUnits = mkOpt (listOf str) [ ] "The systemd *.scope units to wait for before starting Scream";
  };

  config = mkIf cfg.enable {
    boot = {
      kernelModules = [
        "kvm-${cfg.platform}"
        "i915"
        "vhost"
        "vhost_net"
        "vhost_vsock"
        "vhost_scsi"
      ];
    };

    services.qemuGuest.enable = true;

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
        onBoot = "ignore";
        onShutdown = "shutdown";
        allowedBridges = [ "virbr0" "br0" ];
        extraConfig = ''
          user = "${user.name}"
          group = "qemu-libvirtd"
        '';

        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          ovmf = {
            enable = true;
            packages = [ pkgs.OVMFFull.fd ];
          };
          swtpm = enabled;
          vhostUserPackages = [ pkgs.virtiofsd ];
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
          "kvm"
          "disk"
        ];
      };
    };
  };
}
