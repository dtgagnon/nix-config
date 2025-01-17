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
      name = "admin";
      fullName = "";
      email = "gagnon.derek@gmail.com";
    };

    apps = {
      terminals.ghostty.enable = true;
      zen = enabled;
    };

    cli = {
      bat = enabled;
      direnv = enabled;
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
      hyprland.enable = true;
      styling.core = {
        enable = true;
        cursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern_Ice";
          size = 24;
        };
      };
      styling.stylix = {
        enable = true;
        polarity = "dark";
      };
    };
  };
  home.stateVersion = "24.11";
}
