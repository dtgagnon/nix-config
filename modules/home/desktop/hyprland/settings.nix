{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraSettings = {
      input = {
        kb_layout = "us";
        follow_mouse = 1;
      };

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 2;
      };

      decoration = {
        rounding = 5;
      };

      animations = {
        enable = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "workspaces, 1, 6, default"
        ];
      };

      misc = {
        disable_hyprland_logo = true;
        disable_autoreload = true;
      };

      exec_once = [
        "dbus-update-activation-environment --systemd --all"
      ];
    };
  };
}