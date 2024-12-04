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
      hyprland.enable = true;
      styling.stylix = { 
        enable = true;
        wallpaper = pkgs.spirenix.wallpapers.painted-green-mountains;
      };
    };
  };

  home.stateVersion = "24.05";
}
