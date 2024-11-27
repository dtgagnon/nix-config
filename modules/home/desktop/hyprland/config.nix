{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.desktop.hyprland;

  inherit (config.lib.stylix) colors;
in
{ 
  options.${namespace}.desktop.hyprland = {
    extraConfig = mkOpt str "" "Additional hyprland configuration";
    extraMonitorSettings = mkOpt str "" "Additional monitor configurations";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      config = {
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

        source = ["${config.xdg.configFile}/hypr/monitors.conf"];

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
  };
}