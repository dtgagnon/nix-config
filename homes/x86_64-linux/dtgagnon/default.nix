{ lib
, pkgs
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
      name = config.snowfallorg.user.name;
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };
    # ai = {
      # aider = enabled;
    # };

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
