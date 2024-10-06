### Module defining how the home-manager module will operate on a system level. I don't think this needs to be enabled.

{
  options
, config
, pkgs
, lib
, namespace
, ...
}:
with lib;
with lib.${namespace};
let cfg = config.${namespace}.home;
in {
  options.${namespace}.home = with types; {
    configFile = mkOpt attrs { } 
      "A set of files to be managed by home-manager's xdg.configFile";
    extraOptions = 
      mkOpt attrs { } "Options to pass directly to home-manager.";
    file = 
      mkOpt attrs { } (mdDoc "A set of files to be managed by home-manager's `home.file`.");
  };

  config = {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };

    # Configures the home-manager user section.
    snowfallorg.users.${config.${namespace}.user.name}.home.config =
      config.${namespace}.home.extraOptions;

    ${namespace}.home.extraOptions = {
      home.file = mkAliasDefinitions options.${namespace}.home.file;
      home.stateVersion = config.system.stateVersion;

      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.${namespace}.home.configFile;
    };
  };
}
