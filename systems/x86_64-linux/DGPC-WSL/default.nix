{ lib
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [ ./hardware.nix ];

  snowfallorg.users.dtgagnon = {
    admin = true;
  };

  networking.hostName = "DGPC-WSL";

  spirenix = {
    suites = {
      common = enabled;
    };
    services = {
      openssh = enabled;
    };
  };

  system.stateVersion = "24.05";
}
