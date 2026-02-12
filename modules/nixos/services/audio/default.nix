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
  userCfg = config.${namespace}.user;
in
{
  options.${namespace}.services.audio = {
    enable = mkBoolOpt true "Enable typical audio configuration";
    extraPackages =
      mkOpt (types.listOf types.package) [ ]
        "A list of additional audio related packages";
    useMpd = mkBoolOpt false "Use mpd as the default music player daemon";

    mpd = {
      musicDir = mkOpt types.str "/srv/media/music" "Path to the music directory";
      playlistDir = mkOpt types.str "" "Path to the playlist directory (defaults to musicDir/playlists)";
      bindAddress = mkOpt types.str "127.0.0.1" "Address for MPD to bind to";
      openFirewall = mkBoolOpt false "Open firewall for MPD port";
      extraOutputs = mkOpt (types.listOf types.attrs) [ ] "Additional audio outputs for MPD";
    };
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

    (mkIf cfg.useMpd (
      let
        playlistDir =
          if cfg.mpd.playlistDir != ""
          then cfg.mpd.playlistDir
          else "${cfg.mpd.musicDir}/playlists";
      in
      {
        services.mpd = {
          enable = true;
          user = userCfg.name;
          group = "users";
          openFirewall = cfg.mpd.openFirewall;
          settings = {
            music_directory = cfg.mpd.musicDir;
            playlist_directory = playlistDir;
            bind_to_address = cfg.mpd.bindAddress;
            port = 6600;
            audio_output = [
              {
                type = "pipewire";
                name = "PipeWire";
                mixer_type = "software";
              }
            ] ++ cfg.mpd.extraOutputs;
          };
        };

        # MPD needs access to the PipeWire socket when running as user
        systemd.services.mpd.environment = {
          XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.${userCfg.name}.uid}";
        };
      }
    ))
  ];
}
