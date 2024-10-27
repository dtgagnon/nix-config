{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.cli.neovim;

  availableThemes = types.enum [
    "aquarium"
    "decay"
    "edge-dark"
    "everblush"
    "everforest"
    "gruvbox"
    "jellybeans"
    "mountain"
    "nord"
    "oxo-carbon"
    "paradise"
    "tokyonight"
  ];
in
{
  options.${namespace}.cli.neovim = {
    enable = mkBoolOpt false "Enable custom neovim config'd with nixvim";
    theme = mkOpt availableThemes "everforest" "Choose the neovim theme"; ## types default description
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        less
        spirenix.neovim
      ];
      sessionVariables = {
        NVIM_THEME = cfg.theme;
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
