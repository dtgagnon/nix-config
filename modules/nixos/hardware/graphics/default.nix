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
    extraPackages = mkOpt (types.listOf types.str) [ ] "Create a list of pkgs to include under hardware.graphics";
  };

  config = mkIf (cfg.enable && cfg.manufacturer == "nvidia") {
    #graphics card
    services.xserver.videoDrivers = [ "nvidia" ]; #idk if this exists
    hardware = {
      nvidia = {
        open = true; # lib.mkOverride 990 config.hardware.nvidia.package ? open && config.hardware.nvidia.package ? firmware
        modesetting.enable = true;
        nvidiaSettings = true;
        powerManagement = {
          enable = false; #enabled to address sleep/suspend failures
          finegrained = false;
        };
      };
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          libva
          libva-utils
          libva-vdpau-driver
          vdpauinfo
        ];
      };
    };

    environment.systemPackages = [ pkgs.vulkan-tools ];
    # systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  };
}
