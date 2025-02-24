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
    enable = mkBoolOpt false "Enable hardware configuration for basic nvidia gpu settings";
    iGPU = mkOpt (types.nullOr (types.enum [ "intel" "amd" ])) null "Choose the iGPU CPU manufacturer";
    manufacturer = mkOpt (types.nullOr (types.enum [ "nvidia" "intel" "amd" ])) null "Choose graphics card manufacturer";
    nvidiaChannel = mkOpt (types.enum [ "stable" "beta" "latest" ]) "stable" "Declare the nvidia driver release channel (stable, production, beta)";
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.manufacturer == "nvidia") {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware = {
        nvidia = {
          open = true; # lib.mkOverride 990 (config.hardware.nvidia.package ? open && config.hardware.nvidia.package ? firmware);
          package = config.boot.kernelPackages.nvidiaPackages.${cfg.nvidiaChannel};
          modesetting.enable = true;
          powerManagement = {
            enable = false;
            finegrained = false;
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

      environment.variables = {
        NVD_BACKEND = "direct";
        LIBVA_DRIVER_NAME = "nvidia";
      };
      # systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

      boot = {
        blacklistedKernelModules = [ "nouveau" ];
        kernelParams = [
          "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
          "nvidia-drm.modeset=1"
        ];
      };
    })

    (mkIf (cfg.enable && cfg.iGPU == "intel") {
      services.xserver.videoDrivers = [ "modesetting" ];
      hardware.graphics = {
        enable = mkDefault true;
        enable32Bit = mkDefault true;
        extraPackages = with pkgs; [
          libvdpau-va-gl
          libva-vdpau-driver
          intel-vaapi-driver
          intel-media-driver
        ];
      };
    })
  ];
}
