# @tracking: workaround
# @reason: These packages fail to build on nixos-unstable due to cmake4 incompatibility
# @check: evaluate each package from base nixpkgs without this overlay
{ channels, ... }: _: _:
{
  inherit (channels.masterpkgs) libvdpau-va-gl allegro intel-graphics-compiler weylus ctranslate2;
}
