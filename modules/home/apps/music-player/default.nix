{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption types mkIf;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.apps.music-player;
in
{
  options.${namespace}.apps.music-player = {
    enable = mkEnableOption "Enable the default music player application";
    player = mkOpt (types.enum [ null "rmpc" ]) null "The music player application to use";
  };

  config = mkIf cfg.enable {

    programs.rmpc = {
      enable = true;
      config = ''
        (
          address: "100.100.1.2:6600",
          password: None,
          theme: None,
          cache_dir: None,
          on_song_change: None,
          volume_step: 2,
          max_fps: 30,
          scrolloff: 0,
          wrap_navigation: false,
          enable_mouse: true,
          enable_config_hot_reload: true,
          status_update_interval_ms: 1000,
          select_current_song_on_change: false,
          browser_song_sort: [Disc, Track, Artist, Title],
        )
      '';
    };
  };
}
