{ lib, pkgs, inputs, config, modulesPath, ... }:
let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./common/gpu/nvidia/ada-lovelace/
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

    nvidia = {
      open = lib.mkOverride 990 (config.hardware.nvidia.package ? open && config.hardware.nvidia.package ? firmware);
      powerManagement.enable = false;
      nvidiaSettings = true;
    };
    graphics.enable = true;

    bluetooth.enable = true;

    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
}
