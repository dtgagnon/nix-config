{ lib
, pkgs
, config
, namespace
, ...
}:
let
  # Reusable function to build a wallpaper derivation
  mkWallpaper = name: src:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name src;
      dontUnpack = true;
      installPhase = ''
        cp $src $out
      '';
      passthru = {
        # For debugging/reference
        fileName = builtins.baseNameOf src;
      };
    };

  # If you're using lib.snowfall.path.get-file-name-without-extension,
  # be sure that function is actually in scope. Otherwise define your own,
  # for example:
  #
  #  getFileNameWithoutExtension = file: builtins.head (builtins.splitVersion file);
  #
  # For now, we'll assume it's available via lib.snowfall.

  # Recursively crawl a directory building an attribute set:
  #   - If an entry is a directory, recurse to build a sub-attribute set
  #   - If an entry is a file, build a mkWallpaper derivation
  buildWallpapers =
    dir:
      let
        contents = builtins.readDir dir;
        names    = builtins.attrNames contents;
      in
        builtins.listToAttrs (map (entry: let
          path     = "${dir}/${entry}";
          isDir    = contents.${entry} == "directory"; 
          nameNoExt = lib.snowfall.path.get-file-name-without-extension entry;
        in
          if isDir then
            {
              name  = entry;                   # sub-attribute name is the folder name
              value = buildWallpapers path;    # recurse
            }
          else
            {
              name  = nameNoExt;              # attribute name is the file name w/o extension
              value = mkWallpaper nameNoExt path;
            }
        ) names);

  # Build the nested attribute set starting from ./wallpapers
  wallpapers = buildWallpapers ./wallpapers;

in
# Main derivation that installs everything into $out/share/wallpapers
pkgs.stdenvNoCC.mkDerivation {
  name = "wallpapers";
  src  = ./wallpapers;

  installPhase = ''
    mkdir -p "$out/share/wallpapers"
    cp -r ./* "$out/share/wallpapers"
  '';

  # Expose your entire nested set of wallpaper derivations
  passthru = wallpapers;
    # Optionally, you can also expose any top-level "names" you want here
    # inherit wallpapers;
}