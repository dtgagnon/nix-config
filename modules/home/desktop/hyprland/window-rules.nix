{ lib
, config
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;

  # floatWindow =
  #   { windowSizeX
  #   , windowSizeY
  #   , windowAnchorX ? 0.0
  #   , windowAnchorY ? 0.0
  #   , screenAnchorX ? 0.0
  #   , screenAnchorY ? 0.0
  #   , className
  #   }:
  #   let
  #     buildPos = { windowAnchor, screenAnchor, dimensionLetter }: if windowAnchor == "0" then screenAnchor else "${screenAnchor}-${dimensionLetter}-${windowAnchor}";

  #     anchorX = windowSizeX * windowAnchorX;
  #     anchorY = windowSizeY * windowAnchorY;

  #     moveX = buildPos { windowAnchor = anchorX; screenAnchor = screenAnchorX; dimensionLetter = "w"; };
  #     moveY = buildPos { windowAnchor = anchorY; screenAnchor = screenAnchorY; dimensionLetter = "h"; };
  #   in
  #   ''
  #     			float,class:^(${className})
  #     			size ${windowSizeX} ${windowSizeY},class:^(${className})
  #     			move ${moveX} ${moveY},class:^(${className})
  #     		'';
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraWinRules = {
      windowrulev2 = [
        # Aseprite - pixel art editor
        "tile,title:^(Aseprite)$"

        # Discord
        "float,class:^(discord)$"
        "move 50%-w/2 84,class:^(discord)$"
        "size 1600 900,class:^(discord)$"

        # Ghostty - terminal
        "float, class:^(com.mitchellh.ghostty)$"
        "center, class:^(com.mitchellh.ghostty)$"
        "size 1200 800, class:^(com.mitchellh.ghostty)$"
        "bordersize 0, class:^(com.mitchellh.ghostty)$"
        "opacity 0.9 override 0.8 override, class:^(com.mitchellh.ghostty)$"

        #NOTE Window is addressed in related keybind.
        # Kitty - terminal
        # "float,class:^(kitty)$"
        # "center,floating:1,class:kitty"
        # "size 600 900,floating:1,class:kitty"

        #NOTE Window is addressed in related keybind.
        # Yazi - file explorer
        # "float,title:^(Yazi)$"
        # "center,floating:1,title:^(Yazi)$"
        # "size 1200 725,floating:1,title:^(Yazi)$"

        # Workspaces
        "workspace 6 silent, class:^(thunderbird)$"
        "workspace 8, fullscreen, class:^(looking-glass-client)$"

        # Volume Control
        "size 700 450,title:^(Volume Control)$"
        "center,title:^(Volume Control)$"
        "float, title:^(Volume Control)$"

        # Force total opacity
        "opacity 1.0 override 1.0 override, title:^(Picture in Picture)$"
        "opacity 1.0 override 1.0 override,title:^(.*imv.*)$"
        "opacity 1.0 override 1.0 override,title:^(.*mpv.*)$"
        "opacity 1.0 override 1.0 override,class:(Aseprite)"
        "opacity 1.0 override 1.0 override,class:(Unity)"

        #### General Window Rules ####

        # Picture-in-Picture
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "move 100%-h 0, title:^(Picture-in-Picture)$"

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

        #TODO: Figure out if disabling the below config has broken anything or if it had no impact.
        # XWaylandVideoBridge rules: These rules handle screen sharing for X11 apps (like Discord) under Wayland
        # They make the bridge window invisible, prevent animations/focus stealing, and keep it tiny (1x1)
        # This ensures smooth screen sharing without visual interference
        # "opacity 0.0 override,class:^(xwaylandvideobridge)$"
        # "noanim,class:^(xwaylandvideobridge)$"
        # "noinitialfocus,class:^(xwaylandvideobridge)$"
        # "maxsize 1 1,class:^(xwaylandvideobridge)$"
        # "noblur,class:^(xwaylandvideobridge)$"
      ];

      layerrule = [
        "blur, rofi"
      ];
    };
  };
}
