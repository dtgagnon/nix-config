{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.nixosmodule.directory;
  #NOTE: update module directory ^ ^ ^   ^ ^ ^ ^
in
{
  options.${namespace}.nixosmodule.directory = {
    #NOTE: update module path ^ ^   ^ ^ ^ ^
    enable = mkBoolOpt false "Enable XXXXX module";
  };

  config = mkIf cfg.enable { };
}
