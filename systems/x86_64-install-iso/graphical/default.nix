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
    desktop.gnome = enabled;
    hardware.networking = enabled;
    services.openssh = enabled;
    security = {
      age = enabled;
      sops-nix = enabled;
      sudo = enabled;
    };
    system = {
      boot = enabled; #need to make module
      fonts = enabled;
      locale = enabled;
      time = enabled;
      xkb = enabled;
    };
  };
}
