{ lib, pkgs, inputs, config, modulesPath, ... }:
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

  #other hardware
  hardware = {
    #   enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    bluetooth.enable = false;
  };
}

#| Host: Asus UX31A (1.0)
#| Display (CMN1348): 1920x1080 @ 60 Hz in 13″
#| CPU: Intel(R) Core(TM) i5-3317U (4) @ 2.60 GHz
#| GPU: Intel 3rd Gen Core processor Graphics Controller @ 1.05 GHz [Integrated]
#| Memory: 1.74 GiB / 3.72 GiB (47%)
#| Disk (/): 40.32 GiB / 116.32 GiB (35%) - ext4
