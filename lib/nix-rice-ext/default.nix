{ inputs, ... }:
let
  inherit (inputs.nix-rice.lib.nix-rice.color) hexToRgba;
in
{
  # Make hex into rgba that is compatible with being interpolated into a string
  mkRGBA = { hex, alpha ? null }:
    let
      rgba = hexToRgba hex;
      r = rgba.r |> builtins.floor |> builtins.toString;
      g = rgba.g |> builtins.floor |> builtins.toString;
      b = rgba.b |> builtins.floor |> builtins.toString;
      a = rgba.a |> builtins.toString;
    in
    if alpha != null
    then "rgba(${r},${g},${b},${builtins.toString alpha})"
    else "rgba(${r},${g},${b},${a})";
}
