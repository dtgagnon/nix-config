{ inputs, ... }: _final: prev:
{

  ghostty = inputs.ghostty.packages.${prev.system}.default;

  #TODO: Remove below section if keyd works to address caps-swapescape-fix
  # ghostty = inputs.ghostty.packages.${prev.system}.default.overrideAttrs (_oldAttrs: {
  #   patches = [ ./caps-swapescape-fix.patch ];
  # });
}
