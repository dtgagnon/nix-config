{ lib
, pkgs
, config
  # , osConfig ? { }
  # , format ? "unknown"
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled mkRGBA;
  inherit (config.lib.stylix) colors;
in
{
  spirenix = {
    user = {
      fullName = "Derek Gagnon";
      email = "gagnon.derek@gmail.com";
    };

    apps = {
      obsidian = enabled;
      terminals = { ghostty = enabled; };
      todoist = enabled;
      zen = enabled;
    };

    cli = {
      bat = enabled;
      broot = enabled;
      carapace = enabled;
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      git = enabled;
      neovim = enabled;
      network-tools = enabled;
      shells = { nushell = enabled; zsh = enabled; };
      ssh = enabled;
      yazi = enabled;
      zoxide = enabled;
    };

    # desktop = {
    #   styling = {
    #     stylix = {
    #       enable = true;
    #       polarity = "dark";
    #     };
    #     wallpapers-dir = enabled;
    #   };
    # };

    security.sops-nix = enabled;

    # services = {
    #   activity-watch = enabled;
    #   syncthing = enabled;
    # };
  };

  sops.secrets = {
    anthropic_api = { };
    deepseek_api = { };
    moonshot_api = { };
    openai_api = { };
    openrouter_api = { };
  };

  home.stateVersion = "5";
}
