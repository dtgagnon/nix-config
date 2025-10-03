{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) types mkMerge mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.audio;
in
{
  options.${namespace}.services.audio = {
    enable = mkBoolOpt true "Enable typical audio configuration";
    extraPackages =
      mkOpt (types.listOf types.package) [ ]
        "A list of additional audio related packages";
    useMpd = mkBoolOpt false "Use mpd as the default music player daemon";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # General audio needs
      spirenix.user.extraGroups = [ "audio" ];
      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        jack.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };

      environment.systemPackages =
        with pkgs;
        [
          pulsemixer
          pavucontrol
        ]
        ++ cfg.extraPackages;
    })

    (mkIf cfg.useMpd {
      services.mpd = {
        enable = true;
        musicDirectory = "/srv/media/music";
        playlistDirectory = "/srv/media/music/playlists";
        network = {
          listenAddress = "0.0.0.0";
          port = 6600;
        };
      };
    })
  ];
}
