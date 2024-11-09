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
  };

  config = mkIf cfg.enable {
    programs.home-manager.enable = true;
    home.stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.05");

    # spirenix.home.extraOptions = {
    #   home.file = mkAliasDefinitions options.${namespace}.home.file;
    #   xdg.enable = true;
    #   xdg.configFile = mkAliasDefinitions options.${namespace}.home.configFile;
    # };
  };
}
