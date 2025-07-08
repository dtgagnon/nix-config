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
    multiGpuMonitors = mkBoolOpt false "Set to true if monitors are plugged into both the iGPU and dGPU and should be managed by hyprland";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;
      portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    };

    nix.settings = {
      extra-substituters = [ "https://hyprland.cachix.org" ];
      extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
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
      EGL_PLATFORM = "wayland";
      # WLR_DRM_DEVICES = if (config.spirenix.hardware.gpu.iGPU.mfg != null) then "$HOME/.config/hypr/intel-iGPU" else if (cfg.multiGpuMonitors == false) then "" else "$HOME/.config/hypr/nvidia-dGPU"; #TODO: Confirm, but pretty sure that hyprland no longer uses wlroots and uses aquamarine (AQM) instead.
      AQ_DRM_DEVICES = if (config.spirenix.hardware.gpu.iGPU.mfg != null) then "/home/dtgagnon/.config/hypr/intel-iGPU:/home/dtgagnon/.config/hypr/nvidia-dGPU" else if (cfg.multiGpuMonitors == false) then "" else "/home/dtgagnon/.config/hypr/nvidia-dGPU";
    };
  };
}
