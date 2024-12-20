{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.styling.wallpapers;

  inherit (pkgs.spirenix) wallpapers;
in
{
  options.${namespace}.desktop.styling.wallpapers = {
    enable = mkBoolOpt false "Whether or not to add wallpapers to ~/Pictures/wallpapers.";
  };

  config = mkIf cfg.enable {
    home.file = lib.foldl
      (
        acc: name:
          let
            wallpaper = wallpapers.${name};
          in
          acc // { "Pictures/wallpapers/${wallpaper.fileName}".source = wallpaper; }
      )
      { }
      (wallpapers.names);
  };
}
