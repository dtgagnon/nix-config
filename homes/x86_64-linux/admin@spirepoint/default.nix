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
      name = "admin";
      fullName = "";
      email = "gagnon.derek@gmail.com";
    };

    apps = {
      terminals.wezterm = enabled;
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

    security = {
      sops = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
    };
  };

  home.stateVersion = "24.05";
}
