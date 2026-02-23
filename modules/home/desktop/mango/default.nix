{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.mango;
in
{
  options.${namespace}.desktop.mango = {
    enable = mkBoolOpt false "Enable Mango Wayland Compositor desktop sessions";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.mango = {
      enable = true;
    };
  };
}
