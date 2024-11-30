{
  config,
  lib,
  namespace,
  ...
}:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.thefuck;
in {
  options.${namespace}.cli.thefuck = {
    enable = mkBoolOpt false "Whether to enable thefuck command correction tool";
  };

  config = mkIf cfg.enable {
    programs.thefuck = {
      enable = true;
      enableInstantMode = true;  # Enable experimental instant mode for faster corrections
    };
  };
}
