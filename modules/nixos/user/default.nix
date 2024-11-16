{ config
, pkgs
, lib
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.user;
  user = config.${namespace}.user.name;
in
{
  options.${namespace}.user = with types; {
    name = mkOpt str "${user}" "The name to use for the user account.";
    fullName = mkOpt str "Derek Gagnon" "The full name of the user.";
    email = mkOpt str "gagnon.derek@gmail.com" "The email of the user.";
    # initialPassword = mkOpt str "password" "The initial password for the user account.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } (mdDoc "Extra options passed to `users.users.<name>`.");
    prompt-init = mkBoolOpt true "Whether or not to show an initial message when opening a new shell.";
  };

  config = {
    users.users.${user} = {
      inherit (cfg) name;
      hashedPasswordFile = config.sops.secrets."${user}-password.path";
      home = "/persist/home/${user}";
      group = "users";
      extraGroups = cfg.extraGroups;
      isNormalUser = true; # If false, the user is treated as a 'system user'.
      shell = pkgs.nushell;
    } // cfg.extraOptions;

    # User security
    ## Decrypts user's password from secrets.yaml to /run/secrets-for-users/ so it can be used to create users
    sops.secrets."${user}-password".neededForUsers = true;
    users.mutableUsers = false; # Required for password to be set via sops during system activation. Forces user settings to be declared via config exclusively

    # Configure default shell for all users
    programs.zsh.enable = true;
  };
}
