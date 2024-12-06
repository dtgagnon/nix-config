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
  # Get a list of all wallpaper filenames from the ./wallpapers directory
  images = builtins.attrNames (builtins.readDir ./wallpapers);

  # Helper function to create a Nix derivation for a single wallpaper
  # Takes a name and source path as arguments
  mkWallpaper = name: src:
    let
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

  # Create a list of wallpaper names without their file extensions
  names = builtins.map (lib.snowfall.path.get-file-name-without-extension) images;

  # Create an attribute set mapping wallpaper names to their derivations
  # This transforms the list of image files into a set of Nix packages
  wallpapers = lib.foldl
    (
      acc: image:
        let
          # Get the name of the wallpaper without its extension
          name = lib.snowfall.path.get-file-name-without-extension image;
        in
        # Add this wallpaper to the accumulated set
        acc // { "${name}" = mkWallpaper name (./wallpapers + "/${image}"); }
    )
    { }
    images;

  # Define where wallpapers will be installed in the final system
  installTarget = "$out/share/wallpapers";

  # Create installation instructions for each wallpaper
  installWallpapers = builtins.mapAttrs
    (name: wallpaper: ''
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

    # Copy all files from the source directory to the installation directory
    find * -type f -mindepth 0 -maxdepth 0 -exec cp ./{} ${installTarget}/{} ';'
  '';

  # Make wallpaper names and individual wallpaper derivations available
  # to other parts of the Nix configuration
  passthru = {
    inherit names;
  } // wallpapers;
}
