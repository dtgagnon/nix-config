{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.qt;
in
{
  options.${namespace}.desktop.addons.qt = {
    enable = mkBoolOpt false "Whether to enable Qt theming and configuration.";
    platformTheme = mkOpt types.str "gtk" "Qt platform theme to use.";
    style = {
      name = mkOpt types.str "adwaita-dark" "Qt style to use.";
      package = mkOpt types.package pkgs.adwaita-qt "Package providing the Qt style.";
    };
    scaling = mkOpt types.float 1.0 "Global scale factor for Qt applications.";
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme.name = cfg.platformTheme;
      style = {
        name = cfg.style.name;
        package = cfg.style.package;
      };
    };

    home.packages = with pkgs; [
      libsForQt5.qt5ct
      qt6ct
    ];

    home.sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_SCALE_FACTOR = toString cfg.scaling;
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORMTHEME = "qt5ct";
    };
  };
}
