{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.protontricks;
in
{
  options.${namespace}.apps.protontricks = {
    enable = mkBoolOpt false "Whether or not to enable protontricks.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pkgs.protontricks
    ];
  };
  meta.description = "Protontricks module";
}
