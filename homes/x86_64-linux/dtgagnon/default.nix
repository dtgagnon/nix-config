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
      aider-chat = disabled;
    };

    apps = {
      firefox = enabled;
      terminals = { kitty = enabled; wezterm = enabled; };
      windsurf = enabled;
    };

    cli = {
      bottom = enabled;
      direnv = enabled;
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      git = enabled;
      neovim = enabled;
      network-tools = enabled;
      shells.nushell = enabled;
      ssh = enabled;
      zoxide = enabled;
    };

    desktop = {
      # hyprland = {
      #   enable = true;
      #   addons = [ "rofi" "waybar" ];
      #   plugins = [ ];
      # };
      stylix = {
        enable = true;
        imageFilename = "nord-rainbow-dark-nix-ultrawide.png";
      };
    };
  };

  home.stateVersion = "24.05";
}
