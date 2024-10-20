{ channels, ... }:

_final: _prev:
{ inherit (channels.stable) python311Packages; }
# python311Packages = prev.python311Packages // {
#   protobuf = prev.python311Packages.protobuf4;
# };
