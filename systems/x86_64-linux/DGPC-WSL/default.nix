{ lib
, host
, config
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [ ./hardware.nix ];

  networking.hostName = host;

  spirenix = {
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
