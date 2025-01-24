# This module only outputs an organized directory of the wallpapers included in pkgs.spirenix.wallpapers.wallpapers.
{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt snowfallUserList;
  cfg = config.${namespace}.desktop.wallpapers;

  inherit (pkgs.spirenix.wallpapers) wallpapers;

  mkWallpaperEntries = path: set:
    lib.flatten (
      lib.mapAttrsToList
        (name: value:
          if lib.isDerivation value
          then {
            "${path}/${name}".source = value;
          }
          else if lib.isAttrs value
          then mkWallpaperEntries "${path}/${name}" value
          else { }
        )
        set
    );

in
{
  options.${namespace}.desktop.wallpapers = {
    enable = mkBoolOpt false "Whether or not to add wallpapers to ~/Pictures/wallpapers.";
  };

  config = mkIf cfg.enable (builtins.foldl' lib.recursiveUpdate { }
    (map
      (user: {
        snowfallorg.users.${user}.home.config.home.file = lib.foldr lib.recursiveUpdate { }
          (mkWallpaperEntries "Pictures/wallpapers" wallpapers);
      })
      snowfallUserList));
}
