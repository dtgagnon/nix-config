{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.wine;
in
{
  options.${namespace}.apps.wine = {
    enable = mkBoolOpt false "Whether or not to enable wine and winetricks.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wine-wayland
      pkgs.winetricks
      pkgs.geckodriver
    ];
  };
}
