{
  lib,
  pkgs,
  config,
  ...
}:
# User information gathered by Snowfall Lib is available.
let
  name = config.snowfallorg.user.name;
  home = config.snowfallorg.user.home.directory;
in {
  home = {
    packages = with pkgs; [
      neovim
      firefox
    ];

    file = {};

    sessionVariables = {
      EDITOR = "nvim";
    };

    shellAliases = {
      vimdiff = "nvim -d";
    };

    stateVersion = "24.05";
  };
}
