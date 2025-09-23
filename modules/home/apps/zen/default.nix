{ lib
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.apps.zen;
in
{
  options.${namespace}.apps.zen = {
    enable = mkEnableOption "Enable Zen Browser";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.zen-browser.packages.${system}.default ];
  };
}
