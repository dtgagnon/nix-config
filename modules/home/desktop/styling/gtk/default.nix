{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.styling.gtk;

  core = config.spirenix.desktop.styling.core;
in
{
  options.${namespace}.desktop.styling.gtk = {
    enable = mkBoolOpt false "Whether to customize GTK and apply themes.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gtk3.out ];
    gtk = lib.mkForce {
      enable = true;
      theme = {
        name = core.gtk.theme.name;
        package = core.gtk.theme.package;
      };

      iconTheme = {
        package = core.gtk.iconTheme.package;
        name = core.gtk.iconTheme.name;
      };

      cursorTheme = {
        name = core.cursor.name;
        package = core.cursor.package;
        size = core.cursor.size;
      };

      gtk3 = {
        extraConfig = {
          gtk-decoration-layout = "appmenu:none";
          gtk-enable-event-sounds = 0;
          gtk-enable-input-feedback-sounds = 0;
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintfull";
          gtk-error-bell = 0;
          gtk-recent-files-max-age = 0;
          gtk-recent-files-limit = 0;
        };
      };

      gtk4 = {
        extraConfig = {
          gtk-decoration-layout = "appmenu:none";
          gtk-enable-event-sounds = 0;
          gtk-enable-input-feedback-sounds = 0;
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintfull";
          gtk-error-bell = 0;
          gtk-recent-files-max-age = 0;
        };
      };
    };
  };
}
