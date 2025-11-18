{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.grayjay;
in
{
  options.${namespace}.apps.grayjay = {
    enable = mkBoolOpt false "Enable Grayjay";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grayjay
    ];
  };
}
