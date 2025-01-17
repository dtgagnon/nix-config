{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.${namespace}) enabled;
in
{
  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  spirenix = {
    nix = enabled;
    apps.terminals.ghostty = enabled; #need to make sys module?
    tools.general = enabled;
    hardware.networking = enabled;
    security = {
      age = enabled;
      sops-nix = enabled;
      sudo = enabled;
    };
    suites.networking = enabled;
  };
}
