{ inputs
, modulesPath
, ...
}:
let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    common-cpu-intel
    common-gpu-intel
    common-gpu-nvidia-nonprime
    common-pc
    common-pc-ssd
  ];

  #TODO: Update fans module with fancontrol config - config is not correct and the service won't start
  # spirenix.hardware.fans.enable = true;

  #other hardware
  hardware = {
    #   enableAllFirmware = true;
    enableRedistributableFirmware = true;

    bluetooth.enable = true;

    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };

    spacenavd.enable = true;
  };
}
