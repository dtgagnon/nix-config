{ lib, inputs,... }:
let
  inherit (lib) toString;
  inherit (inputs.nix-rice.lib.nix-rice.color) hexToRgba rgba;

  rgbaStr = builtins.toString ${rgba};
in
{
  # Make hex into rgba that is compatible with being interpolated into a string
  mkRGBA = { hex, alpha ? null }:
  let
    rgba = hexToRgba hex;
  in
  if alpha != null then "rgba(${rgba.r}, ${rgba.g}, ${rgba.b}, ${alpha})" else "rgba(${rgba.r}, ${rgba.g}, ${rgba.b}, ${builtins.floatToString rgba.a})";
}