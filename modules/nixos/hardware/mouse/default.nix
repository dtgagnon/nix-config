{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.mouse;
in
{
  options.${namespace}.hardware.mouse = {
    enable = mkBoolOpt true "Whether or not to configure mouse settings.";

    ids = mkOpt (types.listOf types.str) [ ] "Mouse device ids to include in keyd configs.";
  };

  config = lib.mkIf cfg.enable { };
}
