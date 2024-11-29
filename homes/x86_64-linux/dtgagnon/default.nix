{
  lib,
  config,
  osConfig ? { },
  format ? "unknown",
  namespace,
  ...
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
      aider-chat = disabled;
    };

    apps = {
      firefox = enabled;
      terminals = {
        kitty = enabled;
        wezterm = enabled;
      };
      windsurf = enabled;
    };

    cli = {
      bat = enabled;
      bottom = enabled;
      broot = enabled;
      carapace = enabled;
      direnv = enabled;
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      git = enabled;
      neovim = enabled;
      network-tools = enabled;
      shells = { fish = enabled; nushell = enabled; };
      ssh = enabled;
      yazi = enabled;
      zoxide = enabled;
    };

    desktop = {
      hyprland.enable = true;
      stylix = enabled;
    };
  };

  home.stateVersion = "24.05";
}
