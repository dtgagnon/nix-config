{
  lib
, pkgs
, config
, osConfig ? { }
, format ? "unknown"
, namespace
, ...
}:
with lib.${namespace};
{
  sn = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    cli-apps = {
      home-manager = enabled;
      zsh = enabled;
      neovim = enabled;
    };

    tools = {
      comma = enabled;
      git = enabled;
      direnv = enabled;
    };
  };
}
