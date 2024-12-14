{ lib, config, pkgs, ... }:
{
  options.spirenix.apps.bottles.enable = lib.mkEnableOption "Enable bottles";
  config = lib.mkIf config.spirenix.apps.bottles.enable {
    environment.systemPackages = with pkgs; [
      bottles
    ];
  };
}
