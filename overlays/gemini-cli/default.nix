{ channels, ... }: _final: _prev:
{
  inherit (channels.masterpkgs) gemini-cli;
}
