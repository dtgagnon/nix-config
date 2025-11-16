{ channels, ... }: _: prev:
{
  inherit (channels.masterpkgs) element-desktop;
  python313Packages = prev.python313Packages.overrideScope (pyfinal: pyprev: {
    proton-core = channels.masterpkgs.python313Packages.proton-core;
  });
}
