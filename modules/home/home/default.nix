### Module solely for defining the home-manager module state version. Like modules/nixos/home/default.nix, I don't believe this needs to be enabled; it's just declaring something that will get pulled in if home-manager is enabled.

{
  lib,
  osConfig ? { },
  namespace,
  ...
}:
{

  home.stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.05");

}
