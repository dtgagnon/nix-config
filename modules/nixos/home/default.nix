### Module defining how the home-manager module will operate on a system level. I don't think this needs to be enabled.

{
  lib
, config
, options
, namespace
, ...
}:
let
  inherit (lib) mkAliasDefinitions mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.home;
in 
{
  options.${namespace}.home = {
    enable = mkBoolOpt true "Enable Home on NixOS";
    configFile = mkOpt types.attrs { } 
      "A set of files to be managed by home-manager's xdg.configFile";
    extraOptions = 
      mkOpt types.attrs { } "Options to pass directly to home-manager.";
    file = 
      mkOpt types.attrs { } "A set of files to be managed by home-manager's `home.file`.";
  };

  config = mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };

    # Configures the home-manager user section.
    snowfallorg.users.${config.${namespace}.user.name}.home.config =
      config.${namespace}.home.extraOptions;

    ${namespace}.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions options.${namespace}.home.file;

      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.${namespace}.home.configFile;
    };
  };
}
