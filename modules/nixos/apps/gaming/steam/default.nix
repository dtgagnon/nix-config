{ lib, config, pkgs, ... }:
{
  options.spirenix.apps.steam.enable = lib.mkEnableOption "Enable steam";
  config = lib.mkIf config.spirenix.apps.steam.enable {
    environment.systemPackages = with pkgs; [
      steam
    ];
  };
}
