{
  lib,
  config,
  inputs,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.zen;
in
{
  options.${namespace}.apps.zen = {
    enable = mkBoolOpt false "Enable Zen Browser";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.zen-browser.packages.${system}.specific ];
  };
}
