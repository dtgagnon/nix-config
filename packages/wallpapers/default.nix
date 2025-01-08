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
        # e.g., so you can do pkgs.<namespace>.wallpapers.<something>.fileName
        fileName = builtins.baseNameOf src;
      };
    };

  # Recursively crawl a directory (dir) building an attribute set:
  # - If an entry is a directory => recurse and build a sub-attribute set
  # - If an entry is a file => build a mkWallpaper derivation
  buildWallpapers = dir: 
  let
    contents = builtins.readDir dir;    # readDir returns an attrset of { <fileName> = { ... } }
    names    = builtins.attrNames contents;
  in
    lib.attrsets.fromList (lib.map (entry:
    let
      path     = "${dir}/${entry}";
      isDir    = contents.${entry}.directory;  # boolean
      nameNoExt = lib.snowfall.path.get-file-name-without-extension entry;
    in
      if isDir then
        # subdirectory => build a nested attribute set
        {
          name  = entry;
          value = buildWallpapers path;
        }
      else
        # file => build a derivation for the wallpaper
        {
          name  = nameNoExt;
          value = mkWallpaper nameNoExt path;
        }
    ) names);

  # Build the nested attribute set starting from ./wallpapers
  wallpapers = buildWallpapers ./wallpapers;

in
# Now create the "umbrella" derivation that installs them
pkgs.stdenvNoCC.mkDerivation {
  name = "wallpapers";
  src  = ./wallpapers;

  installPhase = ''
    mkdir -p $out/share/wallpapers
    # Copy everything under ./wallpapers into $out/share/wallpapers
    cp -r ./* $out/share/wallpapers
  '';

  # Expose your entire nested set of wallpaper derivations in passthru
  # so that referencing pkgs.<namespace>.wallpapers.<subdir>.<imageName> works.
  passthru = wallpapers;
}