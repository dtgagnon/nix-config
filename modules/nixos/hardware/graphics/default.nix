{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.graphics;
in
{
  options.${namespace}.hardware.graphics = {
    enable = mkBoolOpt false "Enable hardware configuration for basic nvidia gpu settings";
    manufacturer = mkOpt (types.enum [ "nvidia" "intel" "amd" ]) "nvidia" "Choose graphics card manufacturer";
    nvidiaChannel = mkOpt (types.enum [ "stable" "beta" "latest" ]) "stable" "Declare the nvidia driver release channel (stable, production, beta)";
  };

  config = mkIf (cfg.enable && cfg.manufacturer == "nvidia") {
    #graphics card
    services.xserver.videoDrivers = [ "nvidia" ]; #idk if this exists
    hardware = {
      nvidia = {
        open = lib.mkOverride 990 (config.hardware.nvidia.package ? open && config.hardware.nvidia.package ? firmware);
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
  };
}
