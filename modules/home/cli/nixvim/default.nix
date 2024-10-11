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
  cfg = config.${namespace}.cli.nixvim;
in
{
  options.${namespace}.cli.nixvim = {
    enable = mkBoolOpt false "Enable custom neovim config'd with nixvim";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        less
        spirenix.nixvim
      ];
    # programs.neovim = {
    #   enable = true;
    #
    #   defaultEditor = true;
    #   
    #   viAlias = true;
    #   vimAlias = true;
    #
    #   plugins = with pkgs.vimPlugins; [
    #     nvim-lspconfig
    #     neo-tree-nvim
    #     comment-nvim
    #     gruvbox-nvim
    #     neodev-nvim
    #     nvim-cmp
    #     telescope-nvim
    #     telescope-fzf-native-nvim
    #     cmp_luasnip
    #     cmp-nvim-lsp
    #     luasnip
    #     friendly-snippets
    #     lualine-nvim
    #     nvim-web-devicons
    #     (nvim-treesitter.withPlugins (p: [
    #       p.tree-sitter-nix
    #       p.tree-sitter-vim
    #       p.tree-sitter-bash
    #       p.tree-sitter-lua
    #       p.tree-sitter-python
    #       p.tree-sitter-json
    #     ]))
    #     vim-nix
    #   ];
    #   
    #   extraPackages = with pkgs; [
    #     nixd
    #   ];
    #
    #   extraLuaConfig = '' 
    #     ${builtins.readFile ./options.lua}
    #     ${builtins.readFile ./plugin/lsp.lua}
    #     ${builtins.readFile ./plugin/cmp.lua}
    #     ${builtins.readFile ./plugin/telescope.lua}
    #     ${builtins.readFile ./plugin/treesitter.lua}
    #     ${builtins.readFile ./plugin/other.lua}
    #   '';
    # };
    
      sessionVariables = {
        PAGER = "less";
        MANPAGER = "less";
        EDITOR = "nvim";
      };
    };

    xdg.configFile = {
      "dashboard-nvim/.keep".text = "";
    };
  };
}
