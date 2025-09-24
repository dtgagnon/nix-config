{ inputs, ... }:
let
  inherit (inputs.nix-rice.lib.nix-rice.color) hexToRgba;
  toIntText = value: builtins.toString (builtins.floor value);
in
{
  # Make hex into rgba that is compatible with being interpolated into a string
  mkRGBA = { hex, alpha ? null }:
    let
      rgba = hexToRgba hex;
      r = toIntText rgba.r;
      g = toIntText rgba.g;
      b = toIntText rgba.b;
      a = builtins.toString rgba.a;
    in
    if alpha != null
    then "rgba(${r},${g},${b},${builtins.toString alpha})"
    else "rgba(${r},${g},${b},${a})";

  mkRGBA_valOnly = { hex, alpha ? null }:
    let
      rgba = hexToRgba hex;
      r = toIntText rgba.r;
      g = toIntText rgba.g;
      b = toIntText rgba.b;
      a = builtins.toString rgba.a;
    in
    if alpha != null
    then "${r},${g},${b},${builtins.toString alpha}"
    else "${r},${g},${b},${a}";
}
