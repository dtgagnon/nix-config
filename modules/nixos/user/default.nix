{ lib
, host
, pkgs
, config
, options
, namespace
, ...
}:
let
  inherit (lib) mkAliasDefinitions mkMerge mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt snowfallHostUserList;
  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = with types; {
    name = mkOpt str "dtgagnon" "The name to use for the user account";
    extraOptions = mkOpt attrs { } "Extra options passed to `users.users.<name>`";

    shell = mkOpt package pkgs.nushell "The user's default shell";
    prompt-init = mkBoolOpt false "Whether or not to show an initial message when opening a new shell";

    extraUsers = mkOpt (listOf str) [ ] "Additional users to declare for a specific host";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned";

    home.file = mkOpt types.attrs { } "A set of files to be managed by home-manager `home.file`";
    home.configFile = mkOpt attrs { } "An set of files to be managed by home-manager xdg.configFile";
    home.extraOptions = mkOpt attrs { } "Extra options passed to home-manager";
  };

  config = mkMerge [
    (builtins.foldl' lib.recursiveUpdate { }
      (map
        (user: {
          users.users.${user} = {
            isNormalUser = true;
            inherit (cfg) extraGroups shell;
            hashedPasswordFile = config.sops.secrets."${user}-password".path;
            home = "/home/${user}";
            group = "users";
          } // cfg.extraOptions;

          # System level home-manager stuff + sys->home passthrough

          snowfallorg.users.${user} = {
            home.config = {
              home.stateVersion = config.system.stateVersion;
              home.file = mkAliasDefinitions options.${namespace}.user.home.file;
              xdg.enable = true;
              xdg.configFile = mkAliasDefinitions options.${namespace}.user.home.configFile;
            } // cfg.home.extraOptions;

            # User admin permissions (add to wheel)
            admin = mkIf (!builtins.elem "${user}" [ "dtgagnon" "admin" "root" ]) false;
          };

          # User security
          #NOTE: secrets which are needed for ALL created users are dynamically declared through the functions below. Any additional secrets that fit this criteria need to be added inside the function.
          sops.secrets = {
            "${user}-password".neededForUsers = true;

            # SSH Key deposits
            "ssh-keys/${user}-key" = {
              owner = user;
              path = "/persist/home/${user}/.ssh/${user}-key";
            };
            "ssh-keys/${user}-key.pub" = {
              owner = user;
              path = "/persist/home/${user}/.ssh/${user}-key.pub";
            };
          };

          # Add more generic user secrets here..
        })
        (snowfallHostUserList host)
      )
    )
    # ++ cfg.extraUsers is causing infinite recursion issues somehow >_>

    {
      home-manager = {
        useGlobalPkgs = true;
        backupFileExtension = "backup";
      };
      users.mutableUsers = false; # Required for password to be set via sops during system activation. Forces user settings to be declared via config exclusively
    }
  ];
}
