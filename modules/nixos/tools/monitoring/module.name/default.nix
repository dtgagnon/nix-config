{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  # inherit (lib.${namespace}) put_function_here;
  cfg = config.${namespace}.nixosmodule.directory; ## update to module directory
in
{
  options.${namespace}.nixosmodule.directory = { ## update to module directory
    enable = mkEnableOption "Enable XXXXX module";
  };

  config = mkIf cfg.enable {
    
  };
}
