{
  pkgs
, config
, lib
, channel
, namespace
, ...
}:

with lib;
with lib.${namespace};

{

  imports = [ ./hardware.nix ];

  networking.hostName = "DGPC-WSL";

  sn = {
    suites = {
      common = enabled;
    };
  };

  system.stateVersion = "24.05";
}
