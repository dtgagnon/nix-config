# @tracking: workaround
# @reason: These packages have build or runtime issues on nixos-unstable
# @check: evaluate each package from base nixpkgs without this overlay
{ channels, ... }: _: _prev:
{
  inherit (channels.masterpkgs)
    davfs2
    element-desktop
    immich
    nushell
    nushellPlugins
    ;
}
