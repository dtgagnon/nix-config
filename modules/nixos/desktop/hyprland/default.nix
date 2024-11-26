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
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.hyprland;
in
{
  options.${namespace}.desktop.hyprland = let inherit (types) package oneOf path str attrs; in {
    enable = mkBoolOpt false "Enable Hyprland desktop environment";
    package = mkOpt package inputs.hyprland.packages.${system}.hyprland "The Hyprland package to use.";
    settings = mkOpt attrs { } "Extra Hyprland settings to apply.";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      inherit (cfg) package;
      portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    };
    spirenix.desktop.addons.xdg-portal = enabled;

    # programs.hyprlock.enable = true;

    environment.systemPackages = with pkgs; [
    #   libinput
    #   # volumectl
    #   playerctl
      brightnessctl
    #   glib
    #   gtk3.out
    #   gnome-control-center
    #   ags
    #   libdbusmenu-gtk3
    ];
    
    environment.sessionVariables."NIXOS_OZONE_WL" = "1";
    
    # # security.pam.services.hyprlock = { };
  };
}
