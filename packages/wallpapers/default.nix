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
  # Recursively get all image files from the ./wallpapers directory
  getImages = dir:
    let
      entries = builtins.readDir dir;
      files = lib.filterAttrs (name: type: type == "regular") entries;
      dirs = lib.filterAttrs (name: type: type == "directory") entries;
      currentFiles = lib.mapAttrs' (name: _: {
        name = "${dir}/${name}";
        value = "${dir}/${name}";
      }) files;
      subdirFiles = lib.mapAttrs' (name: _: {
        name = name;
        value = getImages "${dir}/${name}";
      }) dirs;
    in
    lib.flatten (lib.attrValues currentFiles ++ lib.attrValues subdirFiles);

  images = getImages ./wallpapers;

  # Helper function to create a Nix derivation for a single wallpaper
  # Takes a name and source path as arguments
  mkWallpaper = path: src:
    let
      # Convert path to package name format (replace / with .)
      name = lib.strings.replaceStrings ["/"] ["."] (lib.removePrefix "./wallpapers/" path);
      # Extract just the filename from the full path
      fileName = builtins.baseNameOf src;
      # Create a simple derivation that just copies the wallpaper file
      pkg = pkgs.stdenvNoCC.mkDerivation {
        inherit name src;

        # No need to unpack since we're just copying files
        dontUnpack = true;

        # Simple installation: just copy the source file to the output
        installPhase = ''
          cp $src $out
        '';

        # Make the filename available to other parts of the configuration
        passthru = {
          inherit fileName;
        };
      };
    in
    pkg;

  # Create an attribute set mapping wallpaper paths to their derivations
  wallpapers = lib.foldl
    (
      acc: path:
        let
          # Get the name of the wallpaper with folder structure
          name = lib.strings.replaceStrings ["/"] ["."] (lib.removePrefix "./wallpapers/" path);
        in
        # Add this wallpaper to the accumulated set
        acc // { "${name}" = mkWallpaper path (./wallpapers + "/${path}"); }
    )
    { }
    images;

  # Define where wallpapers will be installed in the final system
  installTarget = "$out/share/wallpapers";

  # Create installation instructions for each wallpaper
  installWallpapers = builtins.mapAttrs
    (name: wallpaper: ''
      mkdir -p $(dirname ${installTarget}/${wallpaper.fileName})
      cp ${wallpaper} ${installTarget}/${wallpaper.fileName}
    '')
    wallpapers;
in
# Main derivation that creates the complete wallpaper package
pkgs.stdenvNoCC.mkDerivation {
  name = "wallpapers";
  src = ./wallpapers;

  # Installation phase: create directory and copy all wallpapers
  installPhase = ''
    mkdir -p ${installTarget}
    ${lib.concatStringsSep "\n" (lib.attrValues installWallpapers)}
  '';

  # Make wallpaper names and individual wallpaper derivations available
  # to other parts of the Nix configuration
  passthru = {
    inherit images;
  } // wallpapers;
}
