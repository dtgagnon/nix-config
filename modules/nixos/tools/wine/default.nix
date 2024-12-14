{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.tools.wine;
in
{
  options.${namespace}.tools.wine = {
    enable = mkBoolOpt false "Whether or not to enable wine.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pkgs.wine
    ];
  };
  meta.description = "Wine tools module";
}
