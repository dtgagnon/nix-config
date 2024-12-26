{ lib, inputs,... }:
let
  inherit (inputs.nix-rice.lib.nix-rice.color) hexToRgba rgba;

  rgbaStr = builtins.toString rgba;

  # rStr = builtins.toString rgba.r;
  # gStr = builtins.toString rgba.g;
  # bStr = builtins.toString rgba.b;
in
{
  # Make hex into rgba that is compatible with being interpolated into a string
  mkRGBA = { hex, alpha ? null }:
  let
    rgba = hexToRgba hex;
    r = builtins.toString rgba.r;
    g = builtins.toString rgba.g;
    b = builtins.toString rgba.b;
    a = builtins.toString rgba.a;
  in
  if alpha != null
  then "rgba(${r}, ${g}, ${b}, ${builtins.toString alpha})"
  else "rgba(${r}, ${g}, ${b}, ${a})";
}
