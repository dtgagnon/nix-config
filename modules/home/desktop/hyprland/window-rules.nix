{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.${namespace}.desktop.hyprland;
  rule = rules: attrs: attrs // {inherit rules;};
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      # Nix-native window rules
      windowRules = let
        # Media applications
        imv = {class = ["imv"];};
        mpv = {class = ["mpv"];};
        aseprite = {class = ["Aseprite"];};
        unity = {class = ["Unity"];};
        audacious = {class = ["audacious"];};
        neovide = {class = ["neovide"];};

        # System utilities
        floatingKitty = {title = ["^(float_kitty)$"];};
        udiskie = {class = ["udiskie"];};
        transmission = {title = ["^(Transmission)$"];};
        volumeControl = {title = ["^(Volume Control)$"];};
        pavucontrol = {class = ["^(pavucontrol)$"];};
        soundwire = {class = ["^(SoundWireServer)$"];};
        sameboy = {class = ["^(.sameboy-wrapped)$"];};
        zenity = {class = ["^(zenity)$"];};

        # Firefox
        firefoxVideo = {class = ["firefox"];};
        firefoxPip = {title = ["^(Picture-in-Picture)$"];};
        firefoxSharing = {title = ["^(Firefox — Sharing Indicator)$"];};

        # System dialogs
        fileProgress = {class = ["^(file_progress)$"];};
        confirm = {class = ["^(confirm)$"];};
        dialog = {class = ["^(dialog)$"];};
        download = {class = ["^(download)$"];};
        notification = {class = ["^(notification)$"];};
        error = {class = ["^(error)$"];};
        confirmReset = {class = ["^(confirmreset)$"];};
        openFile = {title = ["^(Open File)$"];};
        branchDialog = {title = ["^(branchdialog)$"];};
        confirmReplace = {title = ["^(Confirm to replace files)$"];};
        fileOp = {title = ["^(File Operation Progress)$"];};

        # XWayland bridge
        xwaylandBridge = {class = ["^(xwaylandvideobridge)$"];};

        # Password manager
        bitwarden = {title = [".*Bitwarden.*"];};
      in
        lib.concatLists [
          # Media applications
          (map (rule ["float" "center" "size 1200 725"]) [imv])
          (map (rule ["float" "center" "size 1200 725"]) [mpv])
          (map (rule ["tile"]) [aseprite])
          (map (rule ["opacity 1.0 override 1.0 override"]) [aseprite unity])
          (map (rule ["float" "workspace 8 silent"]) [audacious])
          (map (rule ["tile"]) [neovide])

          # System utilities
          (map (rule ["float" "center" "size 950 600"]) [floatingKitty])
          (map (rule ["float"]) [udiskie transmission volumeControl pavucontrol soundwire sameboy])
          (map (rule ["float" "center" "size 850 500"]) [zenity])

          # Firefox rules
          (map (rule ["idleinhibit fullscreen"]) [firefoxVideo])
          (map (rule ["float" "pin" "opacity 1.0 override 1.0 override"]) [firefoxPip])
          (map (rule ["float" "move 0 0"]) [firefoxSharing])

          # System dialogs
          (map (rule ["float"]) [
            fileProgress
            confirm
            dialog
            download
            notification
            error
            confirmReset
            openFile
            branchDialog
            confirmReplace
            fileOp
          ])

          # XWayland bridge
          (map (rule [
            "opacity 0.0 override"
            "noanim"
            "noinitialfocus"
            "maxsize 1 1"
            "noblur"
          ]) [xwaylandBridge])

          # Password manager
          (map (rule ["float"]) [bitwarden])
        ];

    ## Legacy string-based rules for any rules that don't fit well in the Nix structure
    # extraConfig = ''
    #   # windowrule
    #   windowrule = float,imv
    #   windowrule = center,imv
    #   windowrule = size 1200 725,imv
    #   windowrule = float,mpv
    #   windowrule = center,mpv
    #   windowrule = tile,Aseprite
    #   windowrule = size 1200 725,mpv
    #   windowrule = float,title:^(float_kitty)$
    #   windowrule = center,title:^(float_kitty)$
    #   windowrule = size 950 600,title:^(float_kitty)$
    #   windowrule = float,audacious
    #   windowrule = workspace 8 silent,audacious
    #   windowrule = tile,neovide
    #   windowrule = idleinhibit focus,mpv
    #   windowrule = float,udiskie
    #   windowrule = float,title:^(Transmission)$
    #   windowrule = float,title:^(Volume Control)$
    #   windowrule = float,title:^(Firefox — Sharing Indicator)$
    #   windowrule = move 0 0,title:^(Firefox — Sharing Indicator)$
    #   windowrule = size 700 450,title:^(Volume Control)$
    #   windowrule = move 40 55%,title:^(Volume Control)$

    #   # windowrulev2
    #   windowrulev2 = float,title:^(Picture-in-Picture)$
    #   windowrulev2 = opacity 1.0 override 1.0 override,title:^(Picture-in-Picture)$
    #   windowrulev2 = pin,title:^(Picture-in-Picture)$
    #   windowrulev2 = opacity 1.0 override 1.0 override,title:^(.*imv.*)$
    #   windowrulev2 = opacity 1.0 override 1.0 override,title:^(.*mpv.*)$
    #   windowrulev2 = opacity 1.0 override 1.0 override,class:(Aseprite)
    #   windowrulev2 = opacity 1.0 override 1.0 override,class:(Unity)
    #   windowrulev2 = idleinhibit focus,class:^(mpv)$
    #   windowrulev2 = idleinhibit fullscreen,class:^(firefox)$
    #   windowrulev2 = float,class:^(zenity)$
    #   windowrulev2 = center,class:^(zenity)$
    #   windowrulev2 = size 850 500,class:^(zenity)$
    #   windowrulev2 = float,class:^(pavucontrol)$
    #   windowrulev2 = float,class:^(SoundWireServer)$
    #   windowrulev2 = float,class:^(.sameboy-wrapped)$
    #   windowrulev2 = float,class:^(file_progress)$
    #   windowrulev2 = float,class:^(confirm)$
    #   windowrulev2 = float,class:^(dialog)$
    #   windowrulev2 = float,class:^(download)$
    #   windowrulev2 = float,class:^(notification)$
    #   windowrulev2 = float,class:^(error)$
    #   windowrulev2 = float,class:^(confirmreset)$
    #   windowrulev2 = float,title:^(Open File)$
    #   windowrulev2 = float,title:^(branchdialog)$
    #   windowrulev2 = float,title:^(Confirm to replace files)$
    #   windowrulev2 = float,title:^(File Operation Progress)$

    #   windowrulev2 = opacity 0.0 override,class:^(xwaylandvideobridge)$
    #   windowrulev2 = noanim,class:^(xwaylandvideobridge)$
    #   windowrulev2 = noinitialfocus,class:^(xwaylandvideobridge)$
    #   windowrulev2 = maxsize 1 1,class:^(xwaylandvideobridge)$
    #   windowrulev2 = noblur,class:^(xwaylandvideobridge)$
    # '';
  };
	};
}
