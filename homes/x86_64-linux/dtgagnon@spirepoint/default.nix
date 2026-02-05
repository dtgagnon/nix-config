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
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };

    apps = {
      office.okular-pdf = enabled;
      proton-cloud = enabled;
      terminals.ghostty = enabled;
      zen = enabled;
    };

    cli = {
      bat = enabled;
      broot = enabled;
      carapace = enabled;
      # direnv = enabled;
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      git = enabled;
      neovim = enabled;
      network-tools = enabled;
      shells.nushell = enabled;
      ssh = enabled;
      yazi = enabled;
      zoxide = enabled;
    };

    desktop = {
      styling.core = {
        enable = true;
        cursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Ice";
          size = 24;
        };
        # theme = "catppuccin-frappe";
      };
      styling.stylix = {
        enable = true;
        polarity = "dark";
      };
    };

    services.syncthing = enabled;
  };

  home.stateVersion = "24.11";
}
