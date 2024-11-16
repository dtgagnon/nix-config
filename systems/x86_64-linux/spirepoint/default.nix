{ lib
, config
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
  makeAdmin = if "${config.${namespace}.user.name}" == "dtgagnon" || "admin" || "root" then true else false;
in
{
  imports = [ ./hardware.nix ];

  snowfallorg.users.${config.spirenix.user.name} = {
    admin = makeAdmin;
  };

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
