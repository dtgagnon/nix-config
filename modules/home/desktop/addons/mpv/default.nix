{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.mpv;
in
{
  options.${namespace}.desktop.addons.mpv = {
    enable = mkBoolOpt false "Whether to enable mpv media player with Jellyfin support";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mpv
      jellyfin-mpv-shim
    ];

    programs.mpv = {
      enable = true;

      config = {
        # Hardware acceleration
        hwdec = "auto-safe";
        vo = "gpu";
        profile = "gpu-hq";

        # Video quality
        scale = "ewa_lanczossharp";
        cscale = "ewa_lanczossharp";
        video-sync = "display-resample";
        interpolation = true;
        tscale = "oversample";

        # Audio
        audio-file-auto = "fuzzy";
        audio-pitch-correction = true;
        volume-max = 200;

        # Subtitles
        sub-auto = "fuzzy";
        sub-file-paths = "ass:srt:sub:subs:subtitles";
        slang = "en,eng";
        alang = "en,eng";

        # UI
        osd-level = 1;
        osd-duration = 2500;
        osd-font-size = 32;
        osd-bar-align-y = -1;
        osd-border-size = 1;
        osd-bar-h = 2;
        osd-bar-w = 60;

        # Screenshots
        screenshot-format = "png";
        screenshot-png-compression = 8;
        screenshot-template = "~/Pictures/Screenshots/%F (%P) %n";

        # Streaming optimizations for Jellyfin
        cache = true;
        demuxer-max-bytes = "512M";
        demuxer-max-back-bytes = "256M";

        # Performance
        opengl-pbo = true;
      };

      bindings = {
        # Quality adjustment
        "WHEEL_UP" = "add volume 2";
        "WHEEL_DOWN" = "add volume -2";
        "WHEEL_LEFT" = "seek -10";
        "WHEEL_RIGHT" = "seek 10";

        # Playback speed
        "[" = "multiply speed 0.9091";
        "]" = "multiply speed 1.1";
        "{" = "multiply speed 0.5";
        "}" = "multiply speed 2.0";
        "BS" = "set speed 1.0";

        # Audio/Subtitle tracks
        "a" = "cycle audio";
        "s" = "cycle sub";
        "S" = "cycle sub-visibility";

        # Screenshots
        "Ctrl+s" = "screenshot";
        "Ctrl+S" = "screenshot video";
      };

      scripts = with pkgs.mpvScripts; [
        mpris
        thumbnail
        quality-menu
        sponsorblock
      ];
    };

    # XDG desktop entry for Jellyfin MPV Shim
    xdg.desktopEntries.jellyfin-mpv-shim = mkIf config.${namespace}.desktop.addons.mpv.enable {
      name = "Jellyfin MPV Shim";
      genericName = "Jellyfin Media Player";
      comment = "Cast media from Jellyfin to MPV";
      exec = "jellyfin-mpv-shim";
      icon = "jellyfin";
      terminal = false;
      type = "Application";
      categories = [ "AudioVideo" "Video" "Player" ];
    };
  };
}
