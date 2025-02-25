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
      EGL_PLATFORM = "wayland";
      WLR_DRM_DEVICES = if (config.spirenix.hardware.gpu.iGPU != null) then "$HOME/.config/hypr/intel-iGPU:$HOME/.config/hypr/nvidia-dGPU" else "";
      AQ_DRM_DEVICES = if (config.spirenix.hardware.gpu.iGPU != null) then "$HOME/.config/hypr/intel-iGPU:$HOME/.config/hypr/nvidia-dGPU" else "";
    };
  };
}
