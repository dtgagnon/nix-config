{
  lib,
  pkgs,
  config,
  options,
  namespace,
  ...
}:
let
  inherit (lib) mkAliasDefinitions types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = with types; {
    name = mkOpt str "dtgagnon" "The name to use for the user account";
    initialPassword =
      mkOpt str "n!xos"
        "The default password for the user account if sops fails to import";
    extraOptions = mkOpt attrs { } "Extra options passed to `users.users.<name>`";

    shell = mkOpt package pkgs.nushell "The user's default shell";
    prompt-init = mkBoolOpt false "Whether or not to show an initial message when opening a new shell";

    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned";
    mkAdmin = mkBoolOpt (
      if "${cfg.name}" == "dtgagnon" || "admin" || "root" then true else false
    ) "Declare if the user should be added to wheel group automatically";

    home.file = mkOpt types.attrs { } "A set of files to be managed by home-manager `home.file`";
    home.configFile = mkOpt attrs { } "An set of files to be managed by home-manager xdg.configFile";
    home.extraOptions = mkOpt attrs { } "Extra options passed to home-manager";
  };

  config = {
    users.users.${cfg.name} = {
      isNormalUser = true;
      inherit (cfg) extraGroups initialPassword shell;
      hashedPasswordFile = config.sops.secrets."${cfg.name}-password".path;
      home = "/home/${cfg.name}";
      group = "users";
    } // cfg.extraOptions;

    # User security
    snowfallorg.users.${cfg.name}.admin = cfg.mkAdmin;
    ## Decrypts user's password from secrets.yaml to /run/secrets-for-users/ so it can be used to create users
    sops.secrets."${cfg.name}-password".neededForUsers = true;
    users.mutableUsers = false; # Required for password to be set via sops during system activation. Forces user settings to be declared via config exclusively

    # system level home-manager stuff + sys->home passthrough
    home-manager = {
      useGlobalPkgs = true;
      backupFileExtension = "backup";
    };
    spirenix.user.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions options.${namespace}.user.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.${namespace}.user.home.configFile;
    };
    snowfallorg.users.${cfg.name}.home.config = cfg.home.extraOptions;

  };
}
