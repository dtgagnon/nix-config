{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.freecad;
in
{
  options.${namespace}.apps.freecad = {
    enable = mkBoolOpt false "Enable FreeCAD";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
			freecad-wayland
			spacenavd
		];
  };
}
