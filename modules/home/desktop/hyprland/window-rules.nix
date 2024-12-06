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
        # Image viewer (imv) settings - floating centered window with fixed size
        "float,imv"
        "center,imv"
        "size 1200 725,imv"

        # Media player (mpv) settings - floating centered window with fixed size
        "float,mpv"
        "center,mpv"
        "size 1200 725,mpv"
        "idleinhibit focus,mpv"

        # Pixel art editor settings
        "tile,Aseprite"

        # Floating terminal settings
        "float,title:^(float_kitty)$"
        "center,title:^(float_kitty)$"
        "size 950 600,title:^(float_kitty)$"

        # Music player settings - automatically moved to workspace 8
        "float,audacious"
        "workspace 8 silent,audacious"

        # Editor settings
        "tile,neovide"

        # System tray and utility windows
        "float,udiskie"
        "float,title:^(Transmission)$"
        "float,title:^(Volume Control)$"
        "float,title:^(Firefox — Sharing Indicator)$"
        "move 0 0,title:^(Firefox — Sharing Indicator)$"
        "size 700 450,title:^(Volume Control)$"
        "move 40 55%,title:^(Volume Control)$"
      ];

      windowrulev2 = [
        # Apply blur effect to all non-rofi windows when rofi is open
        "blur,class:^(?!rofi).*$,floating:0,fullscreen:0"
        "blur,class:^(?!rofi).*$,floating:1,fullscreen:0"

        # Picture-in-Picture and Volume Control settings
        "float, title:^(Picture in Picture)$"
        "float, title:^(Volume Control)$"

        # Force full opacity for specific applications
        "opacity 1.0 override 1.0 override, title:^(Picture in Picture)$"
        "opacity 1.0 override 1.0 override,title:^(.*imv.*)$"
        "opacity 1.0 override 1.0 override,title:^(.*mpv.*)$"
        "opacity 1.0 override 1.0 override,class:(Aseprite)"
        "opacity 1.0 override 1.0 override,class:(Unity)"

        # Keep Picture-in-Picture windows pinned
        "pin, title:^(Picture in Picture)$"

        # Prevent screen from sleeping during fullscreen videos/focused media
        "idleinhibit fullscreen, class:^(firefox)$"
        "idleinhibit focus,class:^(mpv)$"

        # Prevent windows from being maximized
        "suppressevent maximize, class:.*"

        # Make all dialog and notification windows floating
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
    };
  };
}
