{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.tools.proton;
in
{
  options.${namespace}.tools.proton = {
    enable = mkBoolOpt false "Whether or not to enable proton.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pkgs.proton
    ];
  };
  meta.description = "Proton tools module";
}
