{
  lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.eza;
in
{
  options.${namespace}.cli.eza = {
    enable = mkBoolOpt true "enable eza";
  };

  config = mkIf cfg.enable {
    programs.eza = {
			enable = true;
			icons = true;
		};
  };
}
