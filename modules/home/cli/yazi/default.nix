{
  config,
  lib,
  namespace,
  ...
}:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.yazi;
in {
  options.${namespace}.cli.yazi = {
    enable = mkBoolOpt false "Whether to enable yazi terminal file manager";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      
      # Default keybindings and settings are quite good
      # Add custom settings here if needed
    };
  };
}
