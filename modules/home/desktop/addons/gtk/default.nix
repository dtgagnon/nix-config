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
  cfg = config.${namespace}.desktop.addons.gtk;
in
{
  options.${namespace}.desktop.addons.gtk = with types; {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
    theme = {
      name = mkOpt str "gruvbox-dark-medium" "The name of the GTK theme to apply.";
      pkg = mkOpt package pkgs.gruvbox-dark-medium "The package to use for the theme.";
    };
    cursor = {
      name = mkOpt str "Bibata-Modern-Ice" "The name of the cursor theme to apply.";
      pkg = mkOpt package pkgs.spirenix.bibata-cursors "The package to use for the cursor theme.";
    };
    icon = {
      name = mkOpt str "Papirus" "The name of the icon theme to apply.";
      pkg = mkOpt package pkgs.papirus-icon-theme "The package to use for the icon theme.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.icon.pkg
      cfg.cursor.pkg
      cfg.theme.pkg
    ];

    home.sessionVariables = {
      XCURSOR_THEME = cfg.cursor.name;
    };

    gtk = {
      enable = true;

      theme = {
        name = cfg.theme.name;
        package = cfg.theme.pkg;
      };

      cursorTheme = {
        name = cfg.cursor.name;
        package = cfg.cursor.pkg;
      };

      iconTheme = {
        name = cfg.icon.name;
        package = cfg.icon.pkg;
      };
    };
  };
}
