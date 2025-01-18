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
