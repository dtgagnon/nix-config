{ lib
, pkgs
, config
, nvimTheme
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.cli.neovim;
in
{
  options.${namespace}.cli.neovim = {
    enable = mkBoolOpt false "Enable custom neovim config'd with nixvim";
    #
    theme = mkOpt types.enum "everforest" "Choose the neovim theme." [
      "everforest"
      "nord"
    ];

    # ai-assisstant = mkOpt types.enum "none" "Choose the neovim compatible ai assisstant." [
    #   "copilot"
    #   "aider-chat"
    # ];
  };

  config = mkIf cfg.enable {
    # ai-assisstant = "none";

    ${nvimTheme} = cfg.theme;

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
