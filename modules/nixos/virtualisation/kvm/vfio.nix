{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types length optionalString concatStringsSep;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.virtualisation.kvm.vfio;
  cfg-kvm = config.${namespace}.virtualisation.kvm;
  user = config.${namespace}.user;
in
{
  options.${namespace}.virtualisation.vfio = {
    enable = mkBoolOpt false "Enable VFIO Configuration";
    vfioIds = mkOpt (types.listOf types.str) [ ] "The hardware IDs to pass through to the VM";
    blacklistNvidia = mkBoolOpt false "Add Nvidia GPU modules to blacklist";

    # disableEFIfb = mkOpt types.bool false "Disables the usage of the EFI framebuffer on boot.";
    # ignoreMSRs = mkBoolOpt false "Disable kvm guest access to model-specific registers";
    # disablePCIeASPM = mkBoolOpt false "Disable PCIe Active-State Power Management";
  };

  config = mkIf (cfg-kvm.enable && cfg.enable) {
		services.udev.extraRules = ''
			SUBSYSTEM=="vfio", OWNER="${user.name}", GROUP="qemu-libvirt", MODE="0660"
		'';
		# NOT USED B/C NEW LOOKING GLASS RC1 PREFERS KVMFR DEVICE APPROACH OVER SHM FILE
		# systemd.tmpfiles.rules = [
		#   "f /dev/shm/looking-glass 0600 ${user.name} qemu-libvirtd -"
		# ];

		boot = {
			extraModulePackages = [ config.boot.kernelPackages.kvmfr ];

			blacklistedKernelModules =
				if cfg.blacklistNvidia then [
					"nvidia"
					"nouveau"
				] else [ ];

			kernelModules = [
				"kvmfr"
				"vfio_pci"
				"vfio_iommu_type1"
				"vfio_virqfd"
				"vfio"
			];
			boot.initrd.kernelModules = [
				"kvmfr"
				"vfio_pci"
				"vfio_iommu_type1"
				"vfio_virqfd"
			];

			kernelParams = [
				"${cfg-kvm.platform}_iommu=on"
				# "${cfg.platform}_iommu=igfx_off"
				"iommu=pt"
				"vfio-pci.ids=${concatStringsSep "," cfg.vfioIds}"
				"video=efifb:off"
				"kvm.ignore_msrs=1"
				"kvm.report_ignored_msrs=0"
			];

			extraModprobeConfig = optionalString (length cfg.vfioIds > 0) ''
				softdep nvidia pre: vfio vfio-pci
				softdep nvidia* pre: vfio vfio-pci
				options vfio-pci ids=${concatStringsSep "," cfg.vfioIds}
				options kvm ignore_msrs=1
				options kvm report_ignored_msrs=0
				options kvmfr static_size_mb=64
			'';
		};
	};
}
