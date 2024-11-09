{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.wallpapers;

  inherit (pkgs.spirenix) wallpapers;
in
{
  options.${namespace}.desktop.addons.wallpapers = {
    enable = mkBoolOpt false "Whether or not to add wallpapers to ~/Pictures/wallpapers.";
  };

  config = {
    spirenix.home.file = lib.foldl
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
