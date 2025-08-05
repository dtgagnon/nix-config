{ lib
, pkgs
, config
, inputs
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge mkForce types optionalString concatStringsSep getExe;
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
      mode = mkOpt (types.enum [ "static" "dynamic" ]) "dynamic" "dynamic: GPU is bound to host at boot. Hooks are required. static: GPU is bound to vfio-pci at boot";
      deviceIds = mkOpt (types.listOf types.str) dGPU.deviceIds "The hardware vendor:product IDs to pass through to the VM";
    };

    #NOTE: Unsure what to do with these options right now. Not sure what they each do for me.
    # # Use `machinectl` and then `machinectl status <name>` to get the unit "*.scope" of the VM
    # machineUnits = mkOpt (listOf str) [ ] "The systemd *.scope units to wait for before starting Scream";
    # disableEFIfb = mkOpt types.bool false "Disables the usage of the EFI framebuffer on boot.";
    ignoreMSRs = mkBoolOpt true "Disable kvm guest access to model-specific registers";
    # disablePCIeASPM = mkBoolOpt false "Disable PCIe Active-State Power Management -sets `pcie_aspm=off` in kernel params";
  };

  config = mkMerge [

    (mkIf cfg.enable {
      boot = {
        blacklistedKernelModules = mkIf (dGPU.mfg == "nvidia") [ "nvidia" "nouveau" ];
        initrd.kernelModules = [ "kvm-${cfg.platform}" "i915" ];
        initrd.availableKernelModules = [ "vfio" "vfio_pci" "vfio_iommu_type1" ];
        kernelModules = [ "vhost" "vhost_net" "vhost_vsock" "vhost_scsi" ];
        kernelParams = [ "${cfg.platform}_iommu=on" "iommu=pt" ];
        extraModprobeConfig = ''
          ${optionalString (cfg.ignoreMSRs) "options kvm ignore_msrs=1"}
          ${optionalString (cfg.ignoreMSRs) "options kvm report_ignored_msrs=0"}
          ${optionalString (cfg.vfio.enable) "options vfio-pci ids=${concatStringsSep "," cfg.vfio.deviceIds}"}
          ${optionalString (cfg.vfio.enable) "softdep nvidia pre: vfio-pci"}
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
        # rustdesk
        # rustdesk-server
      ];
      # spirenix.system.preservation.extraSysDirs = [
      #   { directory = "/var/lib/libvirt"; user = "${user.name}"; group = "qemu-libvirtd"; }
      # ];
    })
    (mkIf (cfg.enable && cfg.lookingGlass.enable) {
      services.udev.extraRules = ''
        SUBSYSTEM=="kvmfr", OWNER="${user.name}", GROUP="qemu-libvirtd", MODE="0660"
      '';
      boot.kernelModules = [ "kvmfr" ];
      boot.extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
      boot.extraModprobeConfig = ''
        options kvmfr static_size_mb=${toString (builtins.elemAt cfg.lookingGlass.kvmfrSize 0)}
      '';
    })
    (mkIf (cfg.enable && cfg.vfio.enable && cfg.vfio.mode == "static") {
      boot.blacklistedKernelModules = mkIf (dGPU.mfg == "nvidia") [ "nvidia" "nouveau" ];
      boot.kernelParams = mkIf (dGPU.mfg == "nvidia") [ "video=efifb:off" /* "nvidia-drm.modeset=1" */ ];
      boot.initrd.kernelModules = [ "vfio" "vfio_pci" "vfio_iommu_type1" ];
      boot.extraModprobeConfig = ''
        options vfio-pci ids=${concatStringsSep "," cfg.vfio.deviceIds}
        softdep nvidia pre: vfio-pci
      '';
      # hardware.nvidia.modesetting.enable = mkForce true;
    })
    (mkIf (cfg.enable && cfg.vfio.enable && cfg.vfio.mode == "dynamic") {
      boot.extraModulePackages = [ config.hardware.nvidia.package config.boot.kernelPackages.vendor-reset ];
      boot.kernelModules = [ "vendor_reset" ];
      services.udev.packages = [ pkgs.spirenix.vendor-reset-udev-rules ];
      boot.kernelParams = [
        "vfio-pci.disable_vga=1"
        "video=vesafb:off,efifb:off"
        (mkForce "nvidia-drm.modeset=0")
        (mkForce "nvidia-drm.fbdev=0")
      ];
      hardware.nvidia = {
        # enable = true; #NOTE Explictly enabled to test if this has impact on dynamic vfio passthrough set up, which boots with vfio-pci taking nvidia gpu right away.
        modesetting.enable = mkForce false;
        nvidiaPersistenced = mkForce true;
      };
      # services.xserver.videoDrivers = mkForce [ "modesetting" "nvidia" ]; # Assumes intel iGPU as host primary
    })
  ];
}
