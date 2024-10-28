{ lib
, pkgs
, inputs
, config
, namespace
, ...
}:
let
	myNixvim = import inputs.neovim.config;
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.neovim;
in
{
  options.${namespace}.cli.neovim = {
    enable = mkBoolOpt false "Enable custom neovim config'd with nixvim";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        less
        spirenix.neovim
      ];
      sessionVariables = {
        PAGER = "less";
        MANPAGER = "less";
        # NPM_CONFIG_PREFIX = "$HOME/.config/.npm-global";
        EDITOR = "nvim";
      };
    };
    xdg.configFile = {
      "dashboard-nvim/.keep".text = "";
    };
  };
}
