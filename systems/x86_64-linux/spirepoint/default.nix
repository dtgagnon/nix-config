{ lib
, config
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [ ./hardware.nix ];

  networking.hostName = "spirepoint";

  spirenix = {
    suites = {
      common = enabled;
      networking = enabled;
    };

    system.network = enabled;

    virtualisation = {
      podman = enabled;
      kvm = enabled;
    };
  };

  system.stateVersion = "24.05";
}
