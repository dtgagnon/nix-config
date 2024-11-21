{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.rofi;
in
{
  options.${namespace}.desktop.addons.rofi = {
    enable = mkBoolOpt false "Whether to enable Rofi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ rofi ];
    programs.rofi = {
      enable = true;
      plugins = with pkgs; [
        rofi-calc
        rofi-emoji
      ];
      extraConfig = {
        configuration = {
          fullscreen = false;
          show-icons = false;
          sidebar-mode = false;
        };

        "*" = {
          background-color = "transparent";
          text-color = "white";
          spacing = 30;
        };

        window = {
          font = "Nerd Font Hack 18";
          fullscreen = true;
          transparency = "background";
          background-color = "#282a36BA";
          children = [ "dummy1" "hdum" "dummy2" ];
        };

        hdum = {
          orientation = "horizontal";
          children = [ "dummy3" "mainbox" "dummy4" ];
        };

        "element selected" = {
          text-color = "#caa9fa";
        };
      };
    };
  };
}