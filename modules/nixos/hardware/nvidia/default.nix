{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.nvidia;
in
{
  options.${namespace}.hardware.nvidia = {
    enable = mkBoolOpt false "Enable hardware configuration for basic nvidia gpu settings";
    extraPackages = mkOpt (types.listOf types.str) [ ] "Create a list of pkgs to include under hardware.graphics";
  };

  config = mkIf cfg.enable {
    #graphics card
    services.xserver.videoDrivers = [ "nvidia" ]; #idk if this exists
    hardware = {
      nvidia = {
        open = lib.mkOverride 990 (config.hardware.nvidia.package ? open && config.hardware.nvidia.package ? firmware);
        powerManagement.enable = true; #enabled to address sleep/suspend failures
        nvidiaSettings = true;
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
  };
}
