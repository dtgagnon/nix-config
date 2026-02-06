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
  # inherit (config.lib.stylix) colors;
in
{
  stylix.enable = false;

  spirenix = {
    apps.terminals.ghostty.enable = false;

    user = {
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };

    # Server mode - desktop apps and styling removed
    cli = {
      bat = enabled;
      broot = enabled;
      carapace = enabled;
      direnv = enabled;
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      git = enabled;
      neovim = enabled;
      network-tools = enabled;
      shells.nushell.enable = false;
      ssh = enabled;
      yazi = enabled;
      zoxide = enabled;
    };

    # Keep syncthing for config sync
    services.syncthing = enabled;
  };

  home.stateVersion = "24.11";
}
