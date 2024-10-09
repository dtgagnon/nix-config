{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.ai.aider;
in 
{ 
  options.${namespace}.ai.aider = {
    enable = mkBoolOpt false "Enable aider terminal chat";
  };
  
  config = mkIf cfg.enable {
    snowfallorg.users.${cfg.name}.home.config.packages = [ pkgs.aider-chat ];
    programs.neovim.plugins = [ pkgs.vimPlugins.aider-nvm ];
  };
}
