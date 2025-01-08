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
      pkg = pkgs.stdenvNoCC.mkDerivation {
        name = builtins.replaceStrings ["/"] ["-"] relPath;
        src = path;

        # No need to unpack since we're just copying files
        dontUnpack = true;

        # Simple installation: create directory structure and copy the file
        installPhase = ''
          mkdir -p $out
          cp $src $out/${fileName}
        '';

        # Make the filename and path available to other parts of the configuration
        passthru = {
          inherit fileName;
          inherit relPath;
        };
      };
    in
    pkg;

  # Create a nested attribute set based on directory structure
  # This transforms the list of image files into a hierarchical set of Nix packages
  wallpapers = lib.foldl
    (
      acc: path:
        let
          # Get the relative path from the wallpapers directory
          relPath = lib.removePrefix (toString ./wallpapers + "/") (toString path);
          # Split the path into components
          components = lib.splitString "/" relPath;
          # Get the name without extension for the last component
          baseName = lib.snowfall.path.get-file-name-without-extension (builtins.baseNameOf path);
          # Create the full attribute path
          attrPath = if builtins.length components > 1
            then (lib.lists.take ((builtins.length components) - 1) components) ++ [baseName]
            else [baseName];
          # Create the nested attribute set
          nestedSet = lib.setAttrByPath attrPath (mkWallpaper path);
        in
        lib.recursiveUpdate acc nestedSet
    )
    { }
    images;

  # Define where wallpapers will be installed in the final system
  installTarget = "$out/share/wallpapers";

  # Helper function to recursively copy wallpapers maintaining structure
  copyWallpapers = path: pkg:
    if builtins.isAttrs pkg && pkg ? outPath
    then ''
      mkdir -p ${installTarget}/$(dirname "${pkg.relPath}")
      cp ${pkg}/* ${installTarget}/${pkg.relPath}
    ''
    else if builtins.isAttrs pkg
    then lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: copyWallpapers "${path}/${name}" value) pkg)
    else "";
in
# Main derivation that creates the complete wallpaper package
pkgs.stdenvNoCC.mkDerivation {
  name = "wallpapers";

  # No source needed as we're copying from derivations
  dontUnpack = true;

  # Installation phase: create directory and copy all wallpapers preserving structure
  installPhase = ''
    mkdir -p ${installTarget}
    ${copyWallpapers "" wallpapers}
  '';

  # Make wallpaper derivations available to other parts of the Nix configuration
  passthru = wallpapers;
}