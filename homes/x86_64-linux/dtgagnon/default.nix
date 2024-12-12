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
      discord = enabled;
      firefox = enabled;
      obsidian = enabled;
      office.okular-pdf = enabled;
      super-productivity = enabled;
      terminals = {
        kitty = enabled;
        wezterm = enabled;
      };
      thunderbird = enabled;
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
        polarity = "dark";
        excludedTargets = [ "neovim" ];
      };
      styling.core = {
        enable = true;
        cursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Ice";
          size = 24;
        };
        wallpaper = pkgs.spirenix.wallpapers.desaturated-grey-flowers;
      };
    };

    services.syncthing = enabled;
  };

  home.stateVersion = "24.05";
}
