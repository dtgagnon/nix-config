{
  lib,
  pkgs,
  config,
  osConfig ? { },
  format ? "unknown",
  namespace,
  ...
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
      firefox = enabled;
      nix-software-center = enabled;
      obsidian = enabled;
      super-productivity = enabled;
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
      shells.nushell = enabled;
      ssh = enabled;
      yazi = enabled;
      zoxide = enabled;
    };

    desktop = {
      hyprland = enabled;
      styling.stylix = {
        enable = true;
        override = { base00 = "#313243"; base03 = "#232332"; base05 = "#4F5165"; };
      };
      styling.core = {
        enable = true;
        cursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Ice";
          size = 24;
        };
        wallpaper = pkgs.spirenix.wallpapers.frosted-purple-snowy-pinetrees;
      };
    };

    services.syncthing = enabled;
  };

  home.stateVersion = "24.05";
}