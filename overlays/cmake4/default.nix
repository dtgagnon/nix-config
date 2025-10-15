{ channels, ... }: _: _:
{
  inherit (channels.masterpkgs) libvdpau-va-gl allegro intel-graphics-compiler weylus ctranslate2;
}
