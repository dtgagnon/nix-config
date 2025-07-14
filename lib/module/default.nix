{ lib, ... }:

let
  inherit (lib) types mkOption;
in
rec {
  ## Create a NixOS module option.
  ## lib.mkOpt nixpkgs.lib.types.str "My default" "Description of my option."
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  ## Create a NixOS module option without a description.
  ## lib.mkOpt' nixpkgs.lib.types.str "My default"
  mkOpt' = type: default: mkOpt type default null;

  ## Create a boolean NixOS module option.
  ## lib.mkBoolOpt true "Description of my option."
  mkBoolOpt = mkOpt types.bool;

  ## Create a boolean NixOS module option without a description.
  ## lib.mkBoolOpt true
  mkBoolOpt' = mkOpt' types.bool;

  ## Create a lines NixOS module option.
  ## lib.mkLinesOpt "" "Description of my option."
  mkLinesOpt = mkOpt types.lines;

  ## Create a lines NixOS module option without a description.
  ## lib.mkLinesOpt' ""
  mkLinesOpt' = mkOpt' types.lines;

  ## Create a deep-merged attribute set NixOS module option.
  ## lib.mkDeepAttrsOpt { } "Description of my option."
  mkDeepAttrsOpt = default: description:
    let
      deepAttrsType = types.submodule {
        freeformType = with types;
          let
            mergable = oneOf [
              (attrsOf mergable)
              (listOf mergable)
              bool
              int
              float
              str
              null
              path
            ];
          in mergable;
        options = { };
      };
    in mkOption {
      inherit default description;
      type = deepAttrsType;
    };

  ## Create a deep-merged attribute set NixOS module option without a description.
  ## lib.mkDeepAttrsOpt' { }
  mkDeepAttrsOpt' = default: mkDeepAttrsOpt default null;

  enabled = {
    ## Quickly enable an option.
    ## services.nginx = enabled;
    enable = true;
  };

  disabled = {
    ## Quickly disable an option.
    ## services.nginx = enabled;
    enable = false;
  };
}
