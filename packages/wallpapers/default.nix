# This is a Nix derivation for managing system wallpapers
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

  # Helper function to get wallpaper metadata
  mkWallpaper = path:
    let
      # Convert path to package name format (replace / with .)
      name = lib.strings.replaceStrings ["/"] ["."] (lib.removePrefix "./wallpapers/" path);
      # Extract just the filename from the full path
      fileName = builtins.baseNameOf path;
    in
    {
      inherit name fileName;
      relativePath = lib.removePrefix "./wallpapers/" path;
    };

  # Create an attribute set mapping wallpaper paths to their metadata
  wallpapers = lib.foldl
    (
      acc: path:
        let
          meta = mkWallpaper path;
        in
        acc // { "${meta.name}" = meta; }
    )
    { }
    images;

  # Define where wallpapers will be installed in the final system
  installTarget = "$out/share/wallpapers";

  # Create installation instructions for all wallpapers
  installScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (name: meta: ''
        mkdir -p $(dirname ${installTarget}/${meta.fileName})
        cp "$src/${meta.relativePath}" ${installTarget}/${meta.fileName}
      '')
      wallpapers
  );
in
# Main derivation that creates the complete wallpaper package
pkgs.stdenvNoCC.mkDerivation {
  name = "wallpapers";
  src = builtins.path {
    path = ./wallpapers;
    name = "wallpapers";
  };

  # Installation phase: create directory and copy all wallpapers
  installPhase = ''
    mkdir -p ${installTarget}
    ${installScript}
  '';

  # Make wallpaper paths available
  passthru = {
    inherit images;
    paths = lib.mapAttrs (name: _: "${installTarget}/${builtins.baseNameOf name}") wallpapers;
  };
}
