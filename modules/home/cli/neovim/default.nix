{ lib
, pkgs
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.neovim;

  #NOTE: Extend nixvim with Stylix theme when Stylix is enabled. https://stylix.danth.me/targets/nixvim.html#standalone-mode
  neovimPackage =
    if config.stylix.enable or false
    then
      (inputs.spirenixvim.packages.${system}.default.override {
        neovim-config = { themeName = "stylix"; };
      }).extend config.stylix.targets.nixvim.exportedModule
    else inputs.spirenixvim.packages.${system}.default;
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
      };
    };

    #TODO: Remove if nothing breaks - dashboard-nvim doesn't actually need this directory
    # xdg.configFile = {
    #   "dashboard-nvim/.keep".text = "";
    # };

    #NOTE: Enable nixvim target for standalone nixvim configuration. This generates the exportedModule that can be used with .extend
    stylix.targets.nixvim = {
      enable = true;
      plugin = "base16-nvim";
      transparentBackground = {
        main = true;
        numberLine = true;
        signColumn = true;
      };
    };
  };
}
