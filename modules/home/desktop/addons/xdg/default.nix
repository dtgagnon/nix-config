{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.xdg;
in
{
  options.${namespace}.desktop.addons.xdg = {
    enable = mkBoolOpt false "manage xdg config";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      HISTFILE = lib.mkForce "${config.xdg.configHome}/bash/history";
      #GNUPGHOME = lib.mkForce "${config.xdg.dataHome}/gnupg";
      GTK2_RC_FILES = lib.mkForce "${config.xdg.configHome}/gtk-2.0/gtkrc";
    };

    xdg = {
      enable = true;
      mimeApps.enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          SCREENSHOTS = "${config.xdg.userDirs.pictures}/screenshots";
        };
      };
    };
  };
}
