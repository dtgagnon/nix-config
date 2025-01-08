# This is a Nix derivation for managing system wallpapers
# It takes standard Nix inputs: lib (for helper functions), pkgs (for dependencies),
# config (for system configuration), and namespace
{ lib
, pkgs
, config
, namespace
, ...
}:
let
  # Get all wallpaper files recursively from the ./wallpapers directory
  images = lib.snowfall.fs.get-files-recursive ./wallpapers;

  # Helper function to create a Nix derivation for a single wallpaper
  # Takes a path as argument
  mkWallpaper = path:
    let
      # Extract just the filename and relative path
      fileName = builtins.baseNameOf path;
      relPath = lib.removePrefix (toString ./wallpapers + "/") (toString path);
      # Create a simple derivation that just copies the wallpaper file
      pkg = pkgs.runCommand (builtins.replaceStrings ["/"] ["-"] relPath) { } ''
        mkdir -p $out
        cp ${path} $out/${fileName}
      '';
    in
    pkg;

  # Create a flat attribute set mapping wallpaper paths to their derivations
  wallpapers = lib.listToAttrs (map
    (path:
      let
        relPath = lib.removePrefix (toString ./wallpapers + "/") (toString path);
        components = lib.splitString "/" relPath;
        baseName = lib.snowfall.path.get-file-name-without-extension (builtins.baseNameOf path);
        attrName = if builtins.length components > 1
          then builtins.concatStringsSep "." ((lib.lists.take ((builtins.length components) - 1) components) ++ [baseName])
          else baseName;
      in
      lib.nameValuePair attrName (mkWallpaper path)
    )
    images);
in
# Main derivation that creates the complete wallpaper package
pkgs.stdenvNoCC.mkDerivation {
  name = "wallpapers";
  src = ./wallpapers;

  # Installation phase: create directory and copy all wallpapers preserving structure
  installPhase = ''
    mkdir -p $out/share/wallpapers
    cp -r $src/* $out/share/wallpapers/
  '';

  # Make wallpaper derivations available to other parts of the Nix configuration
  passthru = wallpapers;
}