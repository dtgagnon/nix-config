{ lib
, pkgs
, config
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
    common-gpu-nvidia-nonprime
    common-pc
    common-pc-ssd
  ];

  #other hardware
  hardware = {
    #   enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    bluetooth.enable = true;

    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}

# Hardware components
# │ MB: Z170A GAMING M5 (MS-7977) (1.0)
# │  : Intel(R) Core(TM) i7-6700K (8) @ 4.20 GHz
# │ 󰍛 : NVIDIA GeForce GTX 1060 3GB [Discrete]
# │ 󰍛 : Intel HD Graphics 530 @ 1.15 GHz [Integrated]
# │ 󰑭 : 649.11 MiB / 15.51 GiB (4%)