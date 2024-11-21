{ lib
, pkgs
, config
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
    package = mkOpt package pkgs.hyprland "The Hyprland package to use.";
    wallpaper = mkOpt (oneOf [ package path str ]) pkgs.spirenix.wallpapers.nord-rainbow-dark-nix "The wallpaper to use.";
    settings = mkOpt attrs { } "Extra Hyprland settings to apply.";
  };

  config = mkIf cfg.enable {
    programs.hyprland.enable = true;

    environment.systemPackages = with pkgs; [
      spirenix.wallpapers
      libinput
      volumectl
      playerctl
      brightnessctl
      glib
      gtk3.out
      gnome.gnome-control-center
      ags
      libdbusmenu-gtk3
    ];

    environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

    # security.pam.services.hyprlock = { };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${lib.getExe pkgs.greetd.tuigreet} --cmd Hyprland";
        };
      };
    };
  };
}
