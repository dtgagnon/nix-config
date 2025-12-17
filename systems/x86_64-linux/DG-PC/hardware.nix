{ pkgs
, inputs
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


  boot.kernelPackages = pkgs.linuxPackages_latest;

  spirenix.hardware = {
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
      nvidiaChannel = "latest";
      nvidiaOpen = true;
      nvidiaPrime = true;
    };
    monitors.pip = {
      enable = true;
      dgpuMonitor = {
        name = "HDMI-A-5";
        spec = "7680x2160@120,0x0,1";
      };
      igpuMonitor = {
        name = "DP-1";
        spec = "7680x2160@60,0x0,1.25";
      };
    };
    keyboard = {
      enable = true;
      model = "qk65v1";
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
