{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.windows-apps;
in
{
  options.${namespace}.apps.windows-apps = {
    enable = mkBoolOpt false "Whether or not to enable Wine, Winetricks, Proton, and Protontricks.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wineWow64Packages.stagingFull
      geckodriver
    ];
  };
}
