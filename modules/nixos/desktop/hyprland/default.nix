{
  lib,
  config,
  inputs,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) enabled mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.hyprland;
in
{
  options.${namespace}.desktop.hyprland = {
    enable = mkBoolOpt false "Enable Hyprland desktop environment";
    package = mkOpt types.package inputs.hyprland.packages.${system}.hyprland "The Hyprland package to use.";
    settings = mkOpt types.attrs { } "Extra Hyprland settings to apply.";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      inherit (cfg) package;
      portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    };

    spirenix.desktop.addons = {
      electron-support = enabled;
      greetd = enabled;
      xdg-portal = enabled;
    };

    environment.sessionVariables = {
      "XDG_SESSION_TYPE" = "wayland";
      # "WLR_BACKEND" = "vulkan";
      # "WLR_RENDERER" = "vulkan";
      # "WLR_NO_HARDWARE_CURSORS" = "1";
      # "WLR_DRM_NO_ATOMIC" = "1";
      "GDK_BACKEND" = "wayland";
      "SDL_VIDEODRIVER" = "wayland";
      "CLUTTER_BACKEND" = "wayland";
      "NIXOS_OZONE_WL" = "1";
    };
  };
}
