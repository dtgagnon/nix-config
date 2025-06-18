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
      iGPU = {
        isPrimary = true;
        mfg = "intel";
        deviceIds = [ "8086:a780" ]; # idk if iGPUs have a second device ID for the audio portion. Guessing not.
        busId = "0000:00:02.0";
      };
      dGPU = {
        mfg = "nvidia";
        deviceIds = [ "10de:2684" "10de:22ba" ];
        busId = "0000:01:00.0";
      };
      nvidiaChannel = "stable";
      nvidiaOpen = true;
      nvidiaPrime = true;
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
