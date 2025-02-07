{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkForce types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.styling.qt;
in
{
  options.${namespace}.desktop.styling.qt = {
    enable = mkBoolOpt false "Whether to enable Qt theming and configuration.";
    scaling = mkOpt types.float 1.0 "Global scale factor for Qt applications.";
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme.name = mkForce config.spirenix.desktop.styling.core.qt.platform;
      style = {
        name = mkForce config.spirenix.desktop.styling.core.qt.style.name;
        package = mkForce config.spirenix.desktop.styling.core.qt.style.package;
      };
    };

    home.packages = with pkgs.kdePackages; [
      qt5compat
      qt6ct
      qtwayland
    ];

    home.sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_SCALE_FACTOR = mkForce (toString cfg.scaling);
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = mkForce "qt6ct";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
