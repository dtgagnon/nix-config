{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkIf types;
  cfg = config.spirenix.desktop.hyprland;

  inherit (config.lib.stylix) colors;
in
{ 
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraConfig = {
      input = {
        kb_layout = "us";
        touchpad = {
          disable_while_typing = false;
        };
      };

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 3;
        active_border_color = "0xff${colors.base07}";
        inactive_border_color = "0xff${colors.base02}";
      };

      decoration = {
        rounding = 5;
      };

      misc = let
        FULLSCREEN_ONLY = 2;
      in {
        vrr = 2;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        variable_framerate = true;
        variable_refresh = FULLSCREEN_ONLY;
        disable_autoreload = true;
      };

      exec_once =
        [
          "dbus-update-activation-environment --systemd --all"
          "systemctl --user import-environment QT_QPA_PLATFORMTHEME"
          # "${pkgs.kanshi}/bin/kanshi"
          "${pkgs.pyprland}/bin/pypr"
          "${pkgs.solaar}/bin/solaar -w hide"
          "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
        ]
        ++ cfg.execOnceExtras;
    };
  };
}