{ lib, inputs, ... }:
let
  inherit (inputs.nix-rice.lib.nix-rice.color) hexToRgba;
  toIntText = value: builtins.toString (builtins.floor value);

  # ANSI 256 color fallbacks (base16 approximations)
  ansi256Fallbacks = {
    base00 = "\\033[38;5;234m"; base01 = "\\033[38;5;236m";
    base02 = "\\033[38;5;238m"; base03 = "\\033[38;5;243m";
    base04 = "\\033[38;5;247m"; base05 = "\\033[38;5;250m";
    base06 = "\\033[38;5;253m"; base07 = "\\033[38;5;255m";
    base08 = "\\033[38;5;203m"; base09 = "\\033[38;5;209m";
    base0A = "\\033[38;5;221m"; base0B = "\\033[38;5;114m";
    base0C = "\\033[38;5;73m";  base0D = "\\033[38;5;75m";
    base0E = "\\033[38;5;176m"; base0F = "\\033[38;5;205m";
  };
in
{
  # Generate true-color (24-bit) ANSI escape code from hex color
  # Example: mkAnsiTrueColor "#ff5500" => "\\033[38;2;255;85;0m"
  mkAnsiTrueColor = hex:
    let
      rgba = hexToRgba hex;
      r = toIntText rgba.r;
      g = toIntText rgba.g;
      b = toIntText rgba.b;
    in
    "\\033[38;2;${r};${g};${b}m";

  # Generate ANSI escape code from stylix base color name
  # Uses true-color when stylix is enabled, falls back to ANSI 256
  # Example: mkAnsiFromStylix config "base0D" => "\\033[38;2;61;116;165m" or "\\033[38;5;75m"
  mkAnsiFromStylix = config: base:
    let
      stylixEnabled = config.stylix.enable or false;
      colors = lib.optionalAttrs stylixEnabled (config.lib.stylix.colors or {});
    in
    if stylixEnabled && colors ? "${base}-rgb-r"
    then "\\033[38;2;${toString colors."${base}-rgb-r"};${toString colors."${base}-rgb-g"};${toString colors."${base}-rgb-b"}m"
    else ansi256Fallbacks.${base} or "\\033[0m";

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
