### Module solely for defining the home-manager module state version. Like modules/nixos/home/default.nix, I don't believe this needs to be enabled; it's just declaring something that will get pulled in if home-manager is enabled.

{
  lib,
  config,
  options,
  osConfig ? { },
  namespace,
  ...
}:
let
  inherit (lib) mkAliasDefinitions mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace};
in 
{
  options.literacy.home = {
    enable = mkBoolOpt true "Enable Home on NixOS";
    file = mkOpt types.attrs { } "A set of files to be managed by home-manager's `home.file`.";
    configFile = mkOpt types.attrs { } "A set of files to be managed by home-manager's `xdg.configFile`.";
    extraOptions = mkOpt types.attrs { } "Options to pass directly to home-manager.";
  };

  config = mkIf cfg.enable {

    ${namespace}.home.extraOptions = {
      home.stateVersion = osConfig.system.stateVersion;
      home.file = mkAliasDefinitions options.${namespace}.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.${namespace}.home.configFile;
    };

    home.stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.05");
  };
}
