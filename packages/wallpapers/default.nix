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

        # Simple installation: just copy the file to output
        installPhase = ''
          mkdir -p $out/share/wallpapers/$(dirname "${relPath}")
          cp $src $out/share/wallpapers/"${relPath}"
        '';

        # Make the filename and path available to other parts of the configuration
        passthru = {
          inherit fileName relPath;
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
in
# Main derivation that creates the complete wallpaper package
pkgs.symlinkJoin {
  name = "wallpapers";
  paths = lib.attrValues (lib.mapAttrs (name: value: 
    if builtins.isAttrs value && value ? outPath
    then value
    else if builtins.isAttrs value
    then pkgs.symlinkJoin {
      name = name;
      paths = lib.attrValues value;
    }
    else value
  ) wallpapers);
  passthru = wallpapers;
}