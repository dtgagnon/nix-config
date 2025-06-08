{ lib
, pkgs
, config
, namespace
, inputs
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
      initrd.kernelModules = [ "kvm-${cfg.platform}" "i915" ];
      kernelModules = [
        "vhost"
        "vhost_net"
        "vhost_vsock"
        "vhost_scsi"
      ];
    };

    virtualisation = {
      libvirt = {
        enable = true;
        connections."qemu:///system" = {
          domains = [
            { definition = ./vm-definitions/win11-GPU.xml; }
          ];
          pools = [
            {
              definition = inputs.NixVirt.lib.pool.writeXML {
                name = "default";
                uuid = "ec93320c-83fc-4b8d-a67d-2eef519cc3fd";
                type = "dir";
                target.path = "/var/lib/libvirt/images";
              };
            }
            {
              definition = inputs.NixVirt.lib.pool.writeXML {
                name = "isos";
                uuid = "7f532314-d910-4237-99ed-ca3441e006a1";
                type = "dir";
                target.path = "/var/lib/libvirt/isos";
              };
            }
            {
              definition = inputs.NixVirt.lib.pool.writeXML {
                name = "nvram";
                uuid = "adda15d7-edf3-4b16-a968-19317c30805a";
                type = "dir";
                target.path = "/var/lib/libvirt/qemu/nvram";
              };
            }
          ];
        };
      };

      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        # allowedBridges = [ "virbr0" "br0" ];
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
          vhostUserPackages = [ pkgs.spirenix.virtiofsd ];
          verbatimConfig = ''
            user = "${user.name}"
            group = "qemu-libvirtd"
            cgroup_device_acl = [
              "/dev/kvmfr0",
              "/dev/vfio/vfio", "/dev/vfio/11", "/dev/vfio/12",
              "/dev/null", "/dev/full", "/dev/zero",
              "/dev/random", "urandom",
              "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            ]
          '';
        };
      };
      spiceUSBRedirection.enable = true;
    };

    services.qemuGuest.enable = true;

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

    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer

      spice
      spice-gtk
      spice-vdagent
      spice-protocol

      virglrenderer
      bridge-utils
      OVMF
      gvfs
      swtpm

      spirenix.virtiofsd
      virtio-win
      win-spice

      quickemu
      inputs.NixVirt.packages.x86_64-linux.default
      # rustdesk # dont think this is used related to VMs
      # rustdesk-server # dont think this is ued related to VMs
    ];

    # spirenix.system.preservation.extraSysDirs = [
    #   { directory = "/var/lib/libvirt"; user = "${user.name}"; group = "qemu-libvirtd"; }
    # ];
  };
}
