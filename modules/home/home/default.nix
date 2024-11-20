{ lib
, config
, options
, namespace
, osConfig ? { }
, ...
}:
let
  inherit (lib) mkIf mkAliasDefinitions types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.home;
in
{
  options.${namespace}.home = {
    enable = mkBoolOpt false "Enable home-manager";
    file = mkOpt types.attrs { } "A set of files to be managed by home-manager's `home.file`.";
    configFile = mkOpt types.attrs { } "A set of files to be managed by home-manager's `xdg.configFile`.";
    extraOptions = mkOpt types.attrs { } "Options to pass directly to home-manager.";

    persistHomeDirs = mkOpt (types.listOf types.str) [ ] "Declare additional user home directories to persist";
    persistHomeFiles = mkOpt (types.listOf types.str) [ ] "Declare additional user home files to persist";
  };

  config = mkIf cfg.enable {
    programs.home-manager.enable = true;

    ${namespace}.home.extraOptions = {
      home.file = mkAliasDefinitions options.${namespace}.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.${namespace}.home.configFile;
    };

    home.stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.05");

    home.persistence."/persist/home/${config.${namespace}.user.name}" = {
      directories = [
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        ".ssh"
        ".config"
        ".local"
      ] ++ cfg.persistHomeDirs;
      files = [
        ".screenrc" 
      ] ++ cfg.persistHomeFiles;
      allowOther = true;
    };
  };
}
