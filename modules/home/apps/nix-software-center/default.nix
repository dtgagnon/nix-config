{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.nix-software-center;
in
{
  options.${namespace}.apps.nix-software-center = {
    enable = mkBoolOpt false "Enable the Nix Software Center module";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.nix-software-center.packages.${system}.nix-software-center ];
  };
}
