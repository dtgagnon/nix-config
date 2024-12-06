# This is a Nix derivation for managing system profile pictures
# It takes standard Nix inputs: lib (for helper functions), pkgs (for dependencies),
# config (for system configuration), and namespace
{ lib
, pkgs
, config
, namespace
, ...
}:
let
  # Get a list of all profile picture filenames from the ./profile-pics directory
  images = builtins.attrNames (builtins.readDir ./profile-pics);

  # Helper function to create a Nix derivation for a single profile picture
  # Takes a name and source path as arguments
  mkProfilePic = name: src:
    let
      # Extract just the filename from the full path
      fileName = builtins.baseNameOf src;
      # Create a simple derivation that just copies the profile picture file
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

  # Create a list of profile picture names without their file extensions
  names = builtins.map (lib.snowfall.path.get-file-name-without-extension) images;

  # Create an attribute set mapping profile picture names to their derivations
  # This transforms the list of image files into a set of Nix packages
  profilePics = lib.foldl
    (
      acc: image:
        let
          # Get the name of the profile picture without its extension
          name = lib.snowfall.path.get-file-name-without-extension image;
        in
        # Add this profile picture to the accumulated set
        acc // { "${name}" = mkProfilePic name (./profile-pics + "/${image}"); }
    )
    { }
    images;

  # Define where profile pictures will be installed in the final system
  installTarget = "$out/share/profile-pics";

  # Create installation instructions for each profile picture
  installProfilePics = builtins.mapAttrs
    (name: profilePic: ''
      cp ${profilePic} ${installTarget}/${profilePic.fileName}
    '')
    profilePics;
in
# Main derivation that creates the complete profile pictures package
pkgs.stdenvNoCC.mkDerivation {
  name = "profile-pics";
  src = ./profile-pics;

  # Installation phase: create directory and copy all profile pictures
  installPhase = ''
    mkdir -p ${installTarget}

    # Copy all files from the source directory to the installation directory
    find * -type f -mindepth 0 -maxdepth 0 -exec cp ./{} ${installTarget}/{} ';'
  '';

  # Make profile picture names and individual profile picture derivations available
  # to other parts of the Nix configuration
  passthru = {
    inherit names;
  } // profilePics;
}