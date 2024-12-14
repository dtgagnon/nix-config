{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.winetricks;
in
{
  options.${namespace}.apps.winetricks = {
    enable = mkBoolOpt false "Whether or not to enable winetricks.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pkgs.winetricks
    ];
  };
    meta.description = "Winetricks module";
}
