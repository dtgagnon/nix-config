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
    common-pc
    common-pc-ssd
  ];

  spirenix.hardware = {
    audio.enable = true;
    gpu = {
      enable = true;
      iGPU = "intel";
      dGPU = "nvidia";
      nvidiaChannel = "stable";
    };
    storage.boot.enable = true;
  };

  #TODO: Update fans module with fancontrol config - config is not correct and the service won't start
  # spirenix.hardware.fans.enable = true;

  # Other hardware
  hardware = {
    #   enableAllFirmware = true;
    enableRedistributableFirmware = true;

    bluetooth.enable = true;

    logitech.wireless = { enable = true; enableGraphical = true; };

    spacenavd.enable = true;
  };
}
