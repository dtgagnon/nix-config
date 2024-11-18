{ lib
, config
, osConfig ? { }
, format ? "unknown"
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  spirenix = {
    user = {
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };

    ai = {
      aider-chat = enabled;
    };

    cli = {
      shells = {
        fish = enabled;
        nushell = enabled;
        zsh = enabled;
      };
      neovim = enabled;
      zoxide = enabled;
      eza = enabled;
      fzf = enabled;
    };

    home = enabled;

    tools = {
      comma = enabled;
      git = enabled;
      direnv = enabled;
    };
  };

  home.stateVersion = "24.05";
}
