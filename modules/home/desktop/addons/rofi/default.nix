{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.rofi;
in
{
  options.${namespace}.desktop.addons.rofi = {
    enable = mkBoolOpt false "Whether to enable rofi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      plugins = with pkgs; [
        rofi-calc
        rofi-emoji
      ];
      theme = mkDefault (
      let
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        configuration = {
          fullscreen = false;
          show-icons = false;
          sidebar-mode = false;
        };

        "*" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "white";
          spacing = 30;
        };

        window = {
          font = mkLiteral "Nerd Font Hack 18";
          fullscreen = true;
          transparency = mkLiteral "background";
          background-color = mkLiteral "#282a36BA";
          children = map mkLiteral [ "dummy1" "hdum" "dummy2" ];
        };

        hdum = {
          orientation = mkLiteral "horizontal";
          children = map mkLiteral [ "dummy3" "mainbox" "dummy4" ];
        };

        "element selected" = {
          text-color = mkLiteral "#caa9fa";
        };
      });
    };
  };
}