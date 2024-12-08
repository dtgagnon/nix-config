{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.styling.qt;

  core = config.spirenix.desktop.styling.core;
in
{
  options.${namespace}.desktop.styling.qt = {
    enable = mkBoolOpt false "Whether to enable Qt theming and configuration.";
    platformTheme = mkOpt types.str "gtk" "Qt platform theme to use.";
    style = {
      name = mkOpt types.str "adwaita-dark" "Qt style to use.";
      package = mkOpt (types.nullOr types.package) null "Package providing the Qt style.";
    };
    scaling = mkOpt types.float 1.0 "Global scale factor for Qt applications.";
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme.name = core.qt.platform or cfg.platformTheme;
      style = {
        name = core.qt.style.name or cfg.style.name;
        package = core.qt.style.package or cfg.style.package;
      };
    };

    home.packages = with pkgs.kdePackages; [
      qt5compat
      qt6ct
      qtwayland
    ];

    home.sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_SCALE_FACTOR = toString cfg.scaling;
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = lib.mkDefault "qt6ct";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
