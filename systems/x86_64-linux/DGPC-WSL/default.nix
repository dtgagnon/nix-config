{
  lib
, channel
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in 
{
  imports = [ ./hardware.nix ];

  networking.hostName = "DGPC-WSL";

  spirenix = {
    suites = {
      common = enabled;
    };
  };

  system.stateVersion = "24.05";
}
