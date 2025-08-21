{ inputs, ... }: _final: prev:
{
  ghostty = inputs.ghostty.packages.${prev.system}.default;
}
