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

  networking.hostName = "spirepoint-dev";

  spirenix = {
    system.network = enabled;
    suites = {
      common = enabled;
      networking = enabled;
    };
    virtualisation = {
      podman = enabled;
      kvm = enabled;
    };
  };

  system.stateVersion = "24.05";
}
