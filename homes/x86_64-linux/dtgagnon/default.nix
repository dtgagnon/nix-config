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
      terminals.wezterm = enabled;
      windsurf = enabled;
    };

    cli = {
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      neovim = enabled;
      shells.nushell = enabled;
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

    home = {
      enable = true;
      persistHomeDirs = [ "proj" "derek-homes-test" ];
    };

    tools = {
      comma = enabled;
      git = enabled;
      direnv = enabled;
    };
  };

  home.stateVersion = "24.05";
}
