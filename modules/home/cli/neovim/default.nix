{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.neovim;

  # Extend nixvim with Stylix theme when Stylix is enabled
  # This follows the Stylix standalone mode documentation:
  # https://stylix.danth.me/targets/nixvim.html#standalone-mode
  neovimPackage =
    if config.stylix.enable or false
    then
      # First configure to use stylix theme, then extend with Stylix's exported module
      (pkgs.spirenix-nvim.neovim.override {
        neovim-config = { themeName = "stylix"; };
      }).extend config.stylix.targets.nixvim.exportedModule
    else pkgs.spirenix-nvim.neovim;
in
{
  options.${namespace}.cli.neovim = {
    enable = mkBoolOpt false "Enable custom neovim config'd with nixvim";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        pkgs.less
        neovimPackage
      ];
      sessionVariables = {
        PAGER = "less";
        MANPAGER = "less";
        NPM_CONFIG_PREFIX = "$HOME/.config/.npm-global";
      };
    };
    xdg.configFile = {
      "dashboard-nvim/.keep".text = "";
    };
  };
}
