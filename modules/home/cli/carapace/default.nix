{
  config,
  lib,
  namespace,
  ...
}:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.carapace;
in {
  options.${namespace}.cli.carapace = {
    enable = mkBoolOpt false "Whether to enable carapace command completion tool";
  };

  config = mkIf cfg.enable {
    programs.carapace = {
      enable = true;
      
      # Carapace comes with a comprehensive set of completions by default
      # Add any custom configurations here if needed
    };
  };
}
