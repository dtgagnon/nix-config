{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) hexToInt hexToDecString;
in
rec {
  mkRGBA = { hex, providedAlpha ? null }: let
    # Convert hex to int
    hexInt = hexToInt hex;

    # Normalize the input hex string by removing any leading #.    
    cleanHex = if builtins.substring 0 1 hex == "#" then builtins.substring 1 (builtins.stringLength hex - 1) hex else hex;

    # Break up the hex string into its component parts
    ## Parse out the first 6 hex characters
    baseHex = builtins.substring 0 6 cleanHex;

    ## If present, parse out the last 2 characters into alpha color channel
    alphaHex = if builtins.stringLength cleanHex == 8 then builtins.substring 6 2 cleanHex else null;

    # Split the hex into RGB
    r = builtins.substring 0 2 baseHex;
    g = builtins.substring 2 2 baseHex;
    b = builtins.substring 4 2 baseHex;

    # Determine alpha priority: explicit providedAlpha > alpha from hex > default 1.0
    a = if providedAlpha != null then
          providedAlpha
        else if alphaHex != null then
           hexToDecString hexToInt alphaHex
        else
          1.0;
  in
  "rgba(${r}, ${g}, ${b}, ${a})";
}