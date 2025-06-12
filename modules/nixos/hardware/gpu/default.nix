{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types mkDefault mkMerge;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.gpu;
in
{
  options.${namespace}.hardware.gpu = {
    enable = mkBoolOpt true "Enable hardware configuration for basic nvidia gpu settings";
    iGPU = {
      mfg = mkOpt (types.nullOr (types.enum [ "intel" "amd" ])) null "Choose the iGPU CPU manufacturer";
      deviceIds = mkOpt (types.listOf types.str) [ ] "The device IDs of the iGPU";
      busId = mkOpt (types.nullOr types.str) null "The bus ID of the iGPU";
    };
    dGPU = {
      mfg = mkOpt (types.nullOr (types.enum [ "nvidia" "intel" "amd" ])) null "Choose the dGPU manufacturer";
      deviceIds = mkOpt (types.listOf types.str) [ ] "The device IDs of the dGPU";
      busId = mkOpt (types.nullOr types.str) null "The bus ID of the dGPU";
    };
    nvidiaChannel = mkOpt (types.enum [ "stable" "beta" "latest" ]) "stable" "Declare the nvidia driver release channel (stable, production, beta)";
    nvidiaPrime = mkBoolOpt false "Whether to use nvidia's PRIME dGPU sync magic whatever";
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.dGPU.mfg == "nvidia") {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware = {
        nvidia = {
          open = true; # lib.mkOverride 990 (config.hardware.nvidia.package ? open && config.hardware.nvidia.package ? firmware);
          package = config.boot.kernelPackages.nvidiaPackages.${cfg.nvidiaChannel};
          modesetting.enable = if (config.${namespace}.virtualisation.kvm.vfio.enable && config.${namespace}.virtualisation.kvm.vfio.mode == "dynamic") then false else true;
          powerManagement = {
            enable = false;
            finegrained = false;
          };
          prime = mkIf cfg.nvidiaPrime {
            offload = { enable = true; enableOffloadCmd = true; };
            intelBusId = "${cfg.iGPU.busId}";
            nvidiaBusId = "${cfg.dGPU.busId}";
          };
        };
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            libvdpau-va-gl
            nvidia-vaapi-driver
          ];
        };
      };

      systemd.services.nvidia-suspend.enable = true;
      systemd.services.nvidia-resume.enable = true;

      environment.systemPackages = with pkgs; [
        nvtopPackages.full
        vulkan-tools
      ];

      environment.variables = if (cfg.iGPU.mfg != null) then { } else {
        NVD_BACKEND = "direct";
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
      # systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

      boot = {
        blacklistedKernelModules = [ "nouveau" ];
        kernelParams = if (cfg.iGPU.mfg != null) then [ ] else [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ]
          ++ mkIf (config.${namespace}.virtualisation.kvm.vfio.mode == "static") [ "nvidia-drm.modeset=1" ]
          ++ mkIf (config.${namespace}.virtualisation.kvm.vfio.mode == "dynamic") [ "nvidia-drm.modeset=0" ];
      };
    })

    (mkIf (cfg.enable && cfg.iGPU.mfg == "intel") {
      services.xserver.videoDrivers = [ "modesetting" ];
      hardware.graphics = {
        enable = mkDefault true;
        enable32Bit = mkDefault true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-vaapi-driver
          vpl-gpu-rt
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
      boot = {
        kernelModules = [ "i915" ];
        kernelParams = [
          "i915.force_probe=a780"
          "i915.enable_fbc=1"
          "i915.enable_psr=2"
          "i915.modeset=1"
          (lib.mkForce "nvidia-drm.fbdev=0")
        ];
        # kernelPackages = pkgs.linuxPackages_latest; # For newer iGPUs (13th Gen) for proper kernel support
      };
      environment.variables = {
        LIBVA_DRIVER_NAME = "iHD";
        VDPAU_DRIVER = "va_gl";
        MOZ_DISABLE_RDD_SANDBOX = "1";
      };
    })
  ];
}
