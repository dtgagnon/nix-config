# Under the impression that this module solely providers configurable options to system level modules which want to 'contact' home-manager options, and that this module need not be enabled in the system config.
{ lib
, config
, options
, namespace
, ...
}:
let
  inherit (lib) mkIf mkAliasDefinitions types;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.home;
in
{
  options.${namespace}.home = {
    file = mkOpt types.attrs { } "A set of files to be managed by home-manager's `home.file`.";
    configFile = mkOpt types.attrs { } "A set of files to be managed by home-manager's `xdg.configFile`.";
    extraOptions = mkOpt types.attrs { } "Options to pass directly to home-manager.";
  };

  config = {
    home-manager = {
      useGlobalPkgs = true;
      backupFileExtension = "backup";
    };

    ${namespace}.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions options.${namespace}.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions cfg.configFile;
    };

    snowfallorg.users.${config.${namespace}.user.name}.home.config = cfg.extraOptions;

  };
}
