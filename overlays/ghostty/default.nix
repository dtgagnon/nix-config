{ inputs, ... }: _final: prev:
{
  ghostty = inputs.ghostty.packages.${prev.system}.default.overrideAttrs (_oldAttrs: {
    patches = [ ./caps-swapescape-fix.patch ];
  });
}
