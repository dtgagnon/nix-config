{ lib
, config
, osConfig
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption types mkMerge mkIf;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.apps.music-player;
in
{
  options.${namespace}.apps.music-player = {
    enable = mkEnableOption "Enable the default music player application";
    player = mkOpt (types.enum [ null "ncmpcpp" ]) null "The music player application to use";
  };

  config = mkMerge [
    (mkIf (cfg.player == "ncmpcpp" && osConfig.services.mpd.enable) {
      programs.ncmpcpp = {
        enable = true;
        # bindings = [ # { key = ""; command = ""; } ];
        # settings = { };
        mpdMusicDir = osConfig.services.mpd.musicDirectory;
      };
    })
  ];
}
