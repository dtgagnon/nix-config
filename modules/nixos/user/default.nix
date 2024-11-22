{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = with types; {
    name = mkOpt str "dtgagnon" "The name to use for the user account";
    initialPassword = mkOpt str "n!xos" "The default password for the user account if sops fails to import";
    fullName = mkOpt str "" "The full name of the user";
    email = mkOpt str "" "The email of the user";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned";
    extraOptions = mkOpt attrs { } "Extra options passed to `users.users.<name>`";
    shell = mkOpt package pkgs.nushell "The user's default shell";
    prompt-init = mkBoolOpt false "Whether or not to show an initial message when opening a new shell";

    mkAdmin = mkBoolOpt (if "${cfg.name}" == "dtgagnon" || "admin" || "root" then true else false) "Declare if the user should be added to wheel group automatically";
  };

  config = {
    users.users.${cfg.name} = {
      inherit (cfg) password shell;
      hashedPasswordFile = config.sops.secrets."${cfg.name}-password".path;
      home = "/home/${cfg.name}";
      group = "users";
      extraGroups = cfg.extraGroups;
      isNormalUser = true; # If false, the user is treated as a 'system user'.
    } // cfg.extraOptions;

    snowfallorg.users.${cfg.name}.admin = cfg.mkAdmin;

    # User security
    ## Decrypts user's password from secrets.yaml to /run/secrets-for-users/ so it can be used to create users
    sops.secrets."${cfg.name}-password".neededForUsers = true;
    users.mutableUsers = false; # Required for password to be set via sops during system activation. Forces user settings to be declared via config exclusively
  };

}
