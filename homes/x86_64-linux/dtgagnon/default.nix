{ lib
, pkgs
, inputs
, config
, osConfig ? { }
, format ? "unknown"
, namespace
, spirenix-nvim
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  spirenix = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };

    ai = {
      aider-chat = enabled;
    };

    cli = {
      home-manager = enabled;
      zsh = enabled;

      zoxide = enabled;
      eza = enabled;
      fzf = enabled;
    };

    tools = {
      comma = enabled;
      git = enabled;
      direnv = enabled;
    };
  };
  inputs.neovim.config.spirenix-nvim.nixvim = {
    enable = true;
    themeName = "paradise";
  };
}
