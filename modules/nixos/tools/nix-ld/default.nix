{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.tools.nix-ld;
in
{
  options.${namespace}.tools.nix-ld = {
    enable = mkBoolOpt false "Whether or not to enable nix-ld.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nix-ld ];
  };
}
