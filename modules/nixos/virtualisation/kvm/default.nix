{ lib
, pkgs
, config
, inputs
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge mkForce types optionalString;
  inherit (lib.${namespace}) mkOpt mkBoolOpt enabled;
  cfg = config.${namespace}.virtualisation.kvm;
  user = config.${namespace}.user;
  dGPU = config.${namespace}.hardware.gpu.dGPU;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.virtualisation.kvm = with types; {
    enable = mkBoolOpt false "Enable KVM virtualisation";
    platform = mkOpt (enum [ "amd" "intel" ]) "intel" "The CPU platform of the host machine";
    lookingGlass = {
      enable = mkBoolOpt false "Enable support for looking-glass-client via /dev/kvmfr";
      kvmfrSize = mkOpt (types.listOf types.int) [ 64 ] "The size of the /dev/kvmfr device in MB";
    };
    vfio = {
      enable = mkBoolOpt false "Enable VFIO Configuration";
      dgpuBootCfg = mkOpt (types.enum [ "vfio" "host" ]) "host" "Driver bound to dGPU at boot: 'vfio' = bound to vfio-pci for VMs. 'host' = bound to host GPU driver (nvidia/amdgpu), switched to vfio-pci when VM starts.";
      deviceIds = mkOpt (types.listOf types.str) dGPU.deviceIds "The hardware vendor:product IDs to pass through to the VM";
    };

    #TODO: Unsure what to do with these options right now. Not sure what they each do for me.
    # # Use `machinectl` and then `machinectl status <name>` to get the unit "*.scope" of the VM
    # machineUnits = mkOpt (listOf str) [ ] "The systemd *.scope units to wait for before starting Scream";
    # disableEFIfb = mkOpt types.bool false "Disables the usage of the EFI framebuffer on boot.";
    ignoreMSRs = mkBoolOpt true "Disable kvm guest access to model-specific registers";
    # disablePCIeASPM = mkBoolOpt false "Disable PCIe Active-State Power Management -sets `pcie_aspm=off` in kernel params";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.vfio.enable -> cfg.enable;
          message = "${namespace}.virtualisation.kvm.vfio.enable requires ${namespace}.virtualisation.kvm.enable";
        }
      ];

      boot = {
        initrd.kernelModules = [ "kvm-${cfg.platform}" "i915" ];
        initrd.availableKernelModules = [ "vfio" "vfio_pci" "vfio_iommu_type1" ];
        kernelModules = [ "vhost" "vhost_net" "vhost_vsock" "vhost_scsi" ];
        kernelParams = [ "${cfg.platform}_iommu=on" "iommu=pt" ];
        extraModprobeConfig = ''
          ${optionalString (cfg.ignoreMSRs) "options kvm ignore_msrs=1"}
          ${optionalString (cfg.ignoreMSRs) "options kvm report_ignored_msrs=0"}
        '';
      };

      virtualisation = {
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
            swtpm = enabled;
            vhostUserPackages = [ pkgs.spirenix.virtiofsd ];
            verbatimConfig = ''
              user = "${user.name}"
              group = "qemu-libvirtd"
              cgroup_device_acl = [
                ${optionalString (cfg.lookingGlass.enable) ''"/dev/kvmfr0",''}
                ${optionalString (cfg.vfio.enable) ''"/dev/vfio/vfio", "/dev/vfio/11", "/dev/vfio/12",''}
                "/dev/null", "/dev/full", "/dev/zero",
                "/dev/random", "urandom",
                "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
              ]
            '';
          };
        };
        spiceUSBRedirection.enable = true;
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
      services.qemuGuest.enable = true;
      networking.firewall.trustedInterfaces = [ "virbr0" ];
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
      ];

      #TODO: Get preservation system working for this dir
      # spirenix.system.preservation.extraSysDirs = [
      #   { directory = "/var/lib/libvirt"; user = "${user.name}"; group = "qemu-libvirtd"; }
      # ];
    })

    (mkIf (cfg.enable && cfg.lookingGlass.enable) {
      services.udev.extraRules = ''
        SUBSYSTEM=="kvmfr", KERNEL=="kvmfr*", GROUP="qemu-libvirtd", MODE="0660", TAG+="uaccess"
      '';
      boot.kernelModules = [ "kvmfr" ];
      boot.extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
      boot.extraModprobeConfig = ''
        options kvmfr static_size_mb=${toString (builtins.elemAt cfg.lookingGlass.kvmfrSize 0)}
      '';
    })

    (mkIf (cfg.vfio.enable && cfg.vfio.dgpuBootCfg == "host") {
      boot.blacklistedKernelModules = mkIf (dGPU.mfg == "nvidia") [ "nouveau" ];
      boot.initrd.kernelModules = [ "vfio" "vfio_pci" "vfio_iommu_type1" ];
      boot.extraModulePackages = [ config.hardware.nvidia.package config.boot.kernelPackages.vendor-reset ];
      boot.kernelModules = [ "vendor_reset" ];
      services.udev.packages = [ pkgs.spirenix.vendor-reset-udev-rules ];
      boot.kernelParams = [
        "video=vesafb:off,efifb:off"
      ];
      hardware.nvidia = {
        modesetting.enable = mkForce false;
        nvidiaPersistenced = mkForce true;
      };
    })

    #NOTE: vfio mode is pretty niche. Only useful if you need the vfio-pci driver to have the dGPU at boot.
    #NOTE: This is necessary to pre-empt nvidia or other default drivers from grabbing the dGPU before vfio-pci can.
    (mkIf (cfg.vfio.enable && cfg.vfio.dgpuBootCfg == "vfio") {
      boot.blacklistedKernelModules = mkIf (dGPU.mfg == "nvidia") [ "nvidia" "nouveau" ];
      boot.kernelParams = mkIf (dGPU.mfg == "nvidia") [ "video=efifb:off" ];
      boot.initrd.kernelModules = [ "vfio" "vfio_pci" "vfio_iommu_type1" ];
      boot.extraModprobeConfig = ''
        options vfio-pci ids=${lib.concatStringsSep "," cfg.vfio.deviceIds}
        softdep nvidia pre: vfio-pci
      '';
    })
  ];
}
