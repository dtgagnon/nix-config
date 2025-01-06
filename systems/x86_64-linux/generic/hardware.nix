{ system
, ...
}:
let
  reminder = if system == "generic" then throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config`?" else null;
in
{
  inherit reminder;
}
