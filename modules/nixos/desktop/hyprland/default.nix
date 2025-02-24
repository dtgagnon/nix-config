{ lib
, pkgs
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) enabled mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.hyprland;
in
{
  options.${namespace}.desktop.hyprland = {
    enable = mkBoolOpt false "Enable Hyprland desktop environment";
    settings = mkOpt types.attrs { } "Extra Hyprland settings to apply.";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;
      portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    };

    spirenix.desktop.addons = {
      electron-support = enabled;
      greetd = enabled;
      keyring = enabled;
      network-manager = enabled;
      thunar = enabled;
      xdg-portal = enabled;
    };

    environment.systemPackages = [ pkgs.kitty ]; #default for when no home configuration has been established
    environment.variables = {
      #   GBM_BACKEND = "nvidia-drm";
      #   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      EGL_PLATFORM = "wayland";
      WLR_DRM_DEVICES = "";
      AQ_DRM_DEVICES = if (config.spirenix.hardware.gpu.iGPU != null) then "/dev/dri/by-path/pci-0000:00:02.0-card:/dev/dri/by-path/pci-0000:01:00.0-card" else "";
    };
  };
}
