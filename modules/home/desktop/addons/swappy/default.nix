{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.swappy;
in
{
  options.${namespace}.desktop.addons.swappy = {
    enable = mkBoolOpt false "Whether to enable Swappy in the desktop environment.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.swappy ];

    xdg.configFile."swappy/config".text = ''
      [Default]
      save_dir=$HOME/Pictures/screenshots
      save_filename_format=%Y%m%d-%H%M%S.png
    '';
    home.file."Pictures/screenshots/.keep".text = "";
  };
}