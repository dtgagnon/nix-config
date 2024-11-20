{ lib
, config
, osConfig ? { }
, format ? "unknown"
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled disabled;
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

    apps = {
      firefox = enabled;
      terminals.wezterm = enabled;
      windsurf = enabled;
    };

    cli = {
      shells = {
        fish = enabled;
        nushell = enabled;
        zsh = disabled;
      };
      neovim = enabled;
      zoxide = enabled;
      eza = enabled;
      fzf = enabled;
    };

    desktop = {
      stylix = {
        enable = true;
      };
    };

    home = {
      enable = true;
      persistHomeDirs = [ "proj" ];
    };

    tools = {
      comma = enabled;
      git = enabled;
      direnv = enabled;
    };
  };

  home.stateVersion = "24.05";
}
