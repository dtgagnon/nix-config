{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.ea-games;
in
{
  options.${namespace}.apps.ea-games = {
    enable = mkBoolOpt false "Enable EA games dependencies";
  };

  config = mkIf cfg.enable {
    # For games that use HTML embedding, need gecko for wine
    environment.systemPackages = [ pkgs.geckodriver ];
  };
}
