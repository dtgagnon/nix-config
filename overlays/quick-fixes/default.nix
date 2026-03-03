# @tracking: workaround
# @reason: These packages have build or runtime issues on nixos-unstable
# @check: evaluate each package from base nixpkgs without this overlay
{ channels, ... }:
_: prev: {
  inherit (channels.masterpkgs)
    davfs2
    element-desktop
    immich
    nushell
    nushellPlugins
    ;

  # glances test_phys_core_returns_int fails in sandbox on aarch64 because
  # /sys/devices/system/cpu/ is unavailable, so phys_core() returns None.
  glances = prev.glances.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [ "test_phys_core_returns_int" ];
  });

  # freecad 1.0.2 fails to build with boost 1.89 (boost_system no longer ships
  # a cmake config; it's been header-only since 1.74). Pin to stablepkgs until
  # nixpkgs fixes it. Tracked: https://github.com/NixOS/nixpkgs/issues/485826
  inherit (channels.stablepkgs)
    freecad
    freecad-wayland
    ;
}
