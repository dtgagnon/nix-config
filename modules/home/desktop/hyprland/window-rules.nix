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
      windowrulev2 = [

        # Aseprite - pixel art editor
        "tile,title:^(Aseprite)$"

        # Discord
        "float,class:^(discord)$"
        "move 0 0,class:^(discord)$"

        # Kitty - terminal
        "float,title:^(float_kitty)$"
        "center,title:^(float_kitty)$"
        "size 950 600,title:^(float_kitty)$"

        # Volume Control
        "size 700 450,title:^(Volume Control)$"
        "move 40 55%,title:^(Volume Control)$"
        "float, title:^(Volume Control)$"

        # Force total opacity
        "opacity 1.0 override 1.0 override, title:^(Picture in Picture)$"
        "opacity 1.0 override 1.0 override,title:^(.*imv.*)$"
        "opacity 1.0 override 1.0 override,title:^(.*mpv.*)$"
        "opacity 1.0 override 1.0 override,class:(Aseprite)"
        "opacity 1.0 override 1.0 override,class:(Unity)"

#### General Window Rules ####

        # Picture-in-Picture
        "float, title:^(Picture in Picture)$"
        "pin, title:^(Picture in Picture)$"

        # Inhibit Idle for fullscreen videos/focused media
        "idleinhibit fullscreen, class:^(firefox)$"
        "idleinhibit focus,class:^(mpv)$"

        # Prevent windows from being maximized
        "suppressevent maximize, class:.*"

        # System tray and utility windows
        "float,title:^(Transmission)$"
        "float,title:^(Volume Control)$"
        "float,title:^(Firefox — Sharing Indicator)$"
        "move 0 0,title:^(Firefox — Sharing Indicator)$"

        # Image viewer (imv) settings - floating centered window with fixed size
        "float,class:^(imv)$"
        "center,class:^(imv)$"
        "size 1200 725,class:^(imv)$"

        # Media player (mpv) settings - floating centered window with fixed size
        "float,class:^(mpv)$"
        "center,class:^(mpv)$"
        "size 1200 725,class:^(mpv)$"
        "idleinhibit focus,class:^(mpv)$"

        # Float dialogs and notifications
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

        # XWaylandVideoBridge rules: These rules handle screen sharing for X11 apps (like Discord) under Wayland
        # They make the bridge window invisible, prevent animations/focus stealing, and keep it tiny (1x1)
        # This ensures smooth screen sharing without visual interference
        "opacity 0.0 override,class:^(xwaylandvideobridge)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
        "maxsize 1 1,class:^(xwaylandvideobridge)$"
        "noblur,class:^(xwaylandvideobridge)$"
      ];

      layerrule = [
        # "blur, waybar"

        "blur, rofi"
        "dimaround, rofi"
        "xray on, rofi"
      ];
    };
  };
}
