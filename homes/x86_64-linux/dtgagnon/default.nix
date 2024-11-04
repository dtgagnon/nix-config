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
      enable = true;
      name = "dtgagnon";
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };

    ai = {
      aider-chat = enabled;
    };

    cli = {
      home-manager = enabled;
      zsh = enabled;
      neovim = enabled;
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
}
