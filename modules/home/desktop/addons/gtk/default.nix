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
in {
  options.${namespace}.desktop.addons.gtk = {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
  };

  config = mkIf cfg.enable {
    gtk = lib.mkForce {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };

      iconTheme = {
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "lavender";
        };
        name = "Papirus-Dark";
      };

      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };

      gtk3.extraCss = config.gtk.gtk4.extraCss;

      gtk3.extraConfig = {
        gtk-toolbar-style = "GTK_TOOLBAR_BOTH";
        gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
        gtk-decoration-layout = "appmenu:none";
        gtk-button-images = 1;
        gtk-menu-images = 1;
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-error-bell = 0;
        gtk-application-prefer-dark-theme = true;
        gtk-recent-files-max-age = 0;
        gtk-recent-files-limit = 0;
      };

      gtk4.extraConfig = {
        gtk-decoration-layout = "appmenu:none";
        gtk-enable-event-sounds = 0;
        gtk-enable-input-feedback-sounds = 0;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-error-bell = 0;
        gtk-application-prefer-dark-theme = true;
        gtk-recent-files-max-age = 0;
      };

      gtk4.extraCss = builtins.readFile ./gtk.css;
    };

    home.sessionVariables.GTK_THEME = "Adwaita:dark";
    home.pointerCursor = lib.mkForce {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };
  };
}