{
  lib,
  config,
  inputs,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.terminals.ghostty;
in
{
  options.${namespace}.apps.terminals.ghostty = {
    enable = mkBoolOpt false "Enable ghostty terminal emulator";
    exampleOption = mkOpt types.str "" "Set xyz";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.ghostty.packages.${system}.default ];
  };
}
