{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf concatStringsSep length listOf optionalString types;
  inherit (lib.${namespace}) mkBoolOpt enabled;
  cfg = config.${namespace}.virtualization.kvm;
  user = config.${namespace}.user;
in
{
  options.${namespace}.virtualization.kvm = with types; {
    enable = mkBoolOpt false "Enable KVM virtualization";
    vfioIds = mkOpt (listOf str) [ ] "The hardware IDs to pass through to the VM";
    platform = mkOpt (enum [ "amd" "intel" ]) "intel" "The CPU platform of the host machine";
    # Use `machinectl` and then `machinectl status <name>` to get the unit "*.scope" of the VM
    machineUnits = mkOpt (listOf str) [ ] "The systemd *.scope units to wait for before starting Scream";
  };

  config = mkIf cfg.enable {
    boot = {
      kernelModules = [
        "kvm-${cfg.platform}"
        "vfio_virqfd"
        "vfio_pci"
        "vfio_iommu_type1"
        "vfio"
      ];
      kernelParams = [
        "${cfg.platform}_iommu=on"
        "${cfg.platform}_iommu=pt"
        "kvm.ignore_msrs=1"
        # "vfio-pci.ids=${concatStringsSep "," cfg.vfioIds}"
      ];
      extraModprobeConfig = optionalString (length cfg.vfioIds > 0) ''
        softdep amdgpu pre: vfio vfio-pci
        options vfio-pci ids=${concatStringsSep "," cfg.vfioIds}
      '';
    };

    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ${user.name} qemu-libvirtd -"
      "f /dev/shm/scream 0660 ${user.name} qemu-libvirtd -"
    ];

    environment.systemPackages = [ pkgs.virt-manager ];

    virtualization = {
      libvirtd = {
        enable = true;
        extraConfig = ''
          user="${user.name}"
        '';

        onBoot = "ignore";
        onShutdown = "shutdown";

        qemu = {
          package = pkgs.qemu_kvm;
          ovmf = enabled;
          swtpm = enabled;
          verbatimConfig = ''
            namespaces = []
            user = "+${builtins.toString config.users.users.${user.name}.uid}"
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

      apps = {
        looking-glass-client = enabled;
      };

      home = {
        extraOptions = {
          systemd.user.services.scream = {
            Unit.Description = "Scream";
            Unit.After = [
              "libvirtd.service"
              "pipewire-pulse.service"
              "pipewire.service"
              "sound.target"
            ] ++ cfg.machineUnits;
            Service.ExecStart = "${pkgs.scream}/bin/scream -n scream -o pulse -m /dev/shm/scream";
            Service.Restart = "always";
            Service.StartLimitIntervalSec = "5";
            Service.StartLimitBurst = "1";
            Install.RequiredBy = cfg.machineUnits;
          };
        };
      };
    };
  };
}