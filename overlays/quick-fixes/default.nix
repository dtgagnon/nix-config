# @tracking: workaround
# @reason: These packages have build or runtime issues on nixos-unstable
# @check: evaluate each package from base nixpkgs without this overlay
{ channels, ... }:
_: _prev: {
  inherit (channels.masterpkgs)
    davfs2
    element-desktop
    immich
    nushell
    nushellPlugins
    ;

  # freecad 1.0.2 fails to build with boost 1.89 (boost_system no longer ships
  # a cmake config; it's been header-only since 1.74). Pin to stablepkgs until
  # nixpkgs fixes it. Tracked: https://github.com/NixOS/nixpkgs/issues/485826
  inherit (channels.stablepkgs)
    freecad
    freecad-wayland
    ;
}
