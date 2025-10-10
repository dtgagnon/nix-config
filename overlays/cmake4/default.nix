{ channels, ... }: _: _:
{
  inherit (channels.masterpkgs) libvdpau-va-gl allegro intel-graphics-compiler weylus;
  inherit (channels.masterpkgs.python313Packages) ctranslate2;
}
