{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraConfig = ''

      # windowrule
      windowrule = float,imv
      windowrule = center,imv
      windowrule = size 1200 725,imv
      windowrule = float,mpv
      windowrule = center,mpv
      windowrule = tile,Aseprite
      windowrule = size 1200 725,mpv
      windowrule = float,title:^(float_kitty)$
      windowrule = center,title:^(float_kitty)$
      windowrule = size 950 600,title:^(float_kitty)$
      windowrule = float,audacious
      windowrule = workspace 8 silent,audacious
      windowrule = tile,neovide
      windowrule = idleinhibit focus,mpv
      windowrule = float,udiskie
      windowrule = float,title:^(Transmission)$
      windowrule = float,title:^(Volume Control)$
      windowrule = float,title:^(Firefox — Sharing Indicator)$
      windowrule = move 0 0,title:^(Firefox — Sharing Indicator)$
      windowrule = size 700 450,title:^(Volume Control)$
      windowrule = move 40 55%,title:^(Volume Control)$

      # windowrulev2
      windowrulev2 = float,title:^(Picture-in-Picture)$
      windowrulev2 = opacity 1.0 override 1.0 override,title:^(Picture-in-Picture)$
      windowrulev2 = pin,title:^(Picture-in-Picture)$
      windowrulev2 = opacity 1.0 override 1.0 override,title:^(.*imv.*)$
      windowrulev2 = opacity 1.0 override 1.0 override,title:^(.*mpv.*)$
      windowrulev2 = opacity 1.0 override 1.0 override,class:(Aseprite)
      windowrulev2 = opacity 1.0 override 1.0 override,class:(Unity)
      windowrulev2 = idleinhibit focus,class:^(mpv)$
      windowrulev2 = idleinhibit fullscreen,class:^(firefox)$
      windowrulev2 = float,class:^(zenity)$
      windowrulev2 = center,class:^(zenity)$
      windowrulev2 = size 850 500,class:^(zenity)$
      windowrulev2 = float,class:^(pavucontrol)$
      windowrulev2 = float,class:^(SoundWireServer)$
      windowrulev2 = float,class:^(.sameboy-wrapped)$
      windowrulev2 = float,class:^(file_progress)$
      windowrulev2 = float,class:^(confirm)$
      windowrulev2 = float,class:^(dialog)$
      windowrulev2 = float,class:^(download)$
      windowrulev2 = float,class:^(notification)$
      windowrulev2 = float,class:^(error)$
      windowrulev2 = float,class:^(confirmreset)$
      windowrulev2 = float,title:^(Open File)$
      windowrulev2 = float,title:^(branchdialog)$
      windowrulev2 = float,title:^(Confirm to replace files)$
      windowrulev2 = float,title:^(File Operation Progress)$

      windowrulev2 = opacity 0.0 override,class:^(xwaylandvideobridge)$
      windowrulev2 = noanim,class:^(xwaylandvideobridge)$
      windowrulev2 = noinitialfocus,class:^(xwaylandvideobridge)$
      windowrulev2 = maxsize 1 1,class:^(xwaylandvideobridge)$
      windowrulev2 = noblur,class:^(xwaylandvideobridge)$
    '';
	};
}
