{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.jellyfin-client;
in
{
  options.${namespace}.apps.jellyfin-client = {
    enable = mkBoolOpt false "Enable a local jellyfin media client";
    package = mkOpt
      (types.enum (
        with pkgs; [
          jellytui
          jellyfin-media-player
          jellyfin-mpv-shim
        ]
      ))
      pkgs.jellytui "Choose the preferred client/frontend";
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # XDG desktop entry for Jellyfin MPV Shim
    xdg.desktopEntries.jellyfin-mpv-shim = mkIf ((cfg.package == pkgs.jellyfin-mpv-shim) && config.${namespace}.desktop.addons.mpv.enable) {
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
