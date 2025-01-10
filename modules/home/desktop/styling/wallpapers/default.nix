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
  options.${namespace}.desktop.styling.wallpapers = {
    enable = mkBoolOpt false "Whether or not to add wallpapers to ~/Pictures/wallpapers.";
  };

  config = mkIf cfg.enable {
    home.file=lib.foldr lib.recursiveUpdate { } (mkWallpaperEntries "Pictures/wallpapers" wallpapers);

    # home.file = lib.foldl
    #   (acc: name:
    #     let 
    #       wallpaper = wallpapers.${name};
    #       baseDir = "Pictures/wallpapers";
    #       subDir = "Pictures/wallpapers/${name}";
    #     in
    #     # If the value has a fileName attribute, it's a wallpaper derivation
    #     if name ? fileName
    #     then acc // { "${baseDir}/${wallpaper.fileName}".source = wallpaper; }
    #     # Otherwise, it's a nested set that needs recursive processing
    #     else acc // { "${subDir}/${wallpaper.fileName}".source = wallpaper; }
    #   )
    #   { }
    #   (builtins.attrNames wallpapers);
  };
}