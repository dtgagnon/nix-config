{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraWinRules = {

      windowrule = [
        "float,imv"
        "center,imv"
        "size 1200 725,imv"
        "float,mpv"
        "center,mpv"
        "tile,Aseprite"
        "size 1200 725,mpv"
        "float,title:^(float_kitty)$"
        "center,title:^(float_kitty)$"
        "size 950 600,title:^(float_kitty)$"
        "float,audacious"
        "workspace 8 silent,audacious"
        "tile,neovide"
        "idleinhibit focus,mpv"
        "float,udiskie"
        "float,title:^(Transmission)$"
        "float,title:^(Volume Control)$"
        "float,title:^(Firefox — Sharing Indicator)$"
        "move 0 0,title:^(Firefox — Sharing Indicator)$"
        "size 700 450,title:^(Volume Control)$"
        "move 40 55%,title:^(Volume Control)$"
      ];

      windowrulev2 = [
        "float, title:^(Picture in Picture)$"
        "float, title:^(Volume Control)$"

        "opacity 1.0 override 1.0 override, title:^(Picture in Picture)$"
        "opacity 1.0 override 1.0 override,title:^(.*imv.*)$"
        "opacity 1.0 override 1.0 override,title:^(.*mpv.*)$"
        "opacity 1.0 override 1.0 override,class:(Aseprite)"
        "opacity 1.0 override 1.0 override,class:(Unity)"

        "pin, title:^(Picture in Picture)$"

        "idleinhibit fullscreen, class:^(firefox)$"
        "idleinhibit focus,class:^(mpv)$"

        "suppressevent maximize, class:.*"

        "float,class:^(file_progress)$"
        "float,class:^(confirm)$"
        "float,class:^(dialog)$"
        "float,class:^(download)$"
        "float,class:^(notification)$"
        "float,class:^(error)$"
        "float,class:^(confirmreset)$"
        "float,class:^(pavucontrol)$"
        "float,title:^(Open File)$"
        "float,title:^(branchdialog)$"
        "float,title:^(Confirm to replace files)$"
        "float,title:^(File Operation Progress)$"

        # attempting to get transparency on rofi
        "opacity 0.75 override 0.75 override, class:^(rofi)$"

        # not sure I use these, they're from borrowed config
        "opacity 0.0 override,class:^(xwaylandvideobridge)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
        "maxsize 1 1,class:^(xwaylandvideobridge)$"
        "noblur,class:^(xwaylandvideobridge)$"
      ];
    };
  };
}
