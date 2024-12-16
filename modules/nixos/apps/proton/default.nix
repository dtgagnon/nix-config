{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.proton;
in
{
  options.${namespace}.apps.proton = {
    enable = mkBoolOpt false "Whether or not to enable proton and protontricks.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pkgs.protonup
      pkgs.protontricks
    ];
  };
}