{ lib
, host
, pkgs
, config
, inputs
, options
, namespace
, ...
}:
let
  inherit (lib) mkAliasDefinitions mkMerge mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt snowfallHostUserList;
  cfg = config.${namespace}.user;
  secretsPath = builtins.toString inputs.nix-secrets;
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
            uid = if user == "dtgagnon" then 1001 else null;
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
            admin = mkIf (!builtins.elem "${user}" [ "dtgagnon" "root" ]) false;
          };

          # User security
          # dtgagnon uses shared.yaml; other users use host-specific sops file
          sops.secrets = let
            sharedFile = lib.optionalAttrs (user == "dtgagnon") {
              sopsFile = "${secretsPath}/sops/shared.yaml";
            };
          in {
            "${user}-password" = { neededForUsers = true; } // sharedFile;

            # SSH Key deposits
            "ssh-keys/${user}-key" = {
              owner = user;
              path = "/persist/home/${user}/.ssh/${user}-key";
            } // sharedFile;
            "ssh-keys/${user}-key.pub" = {
              owner = user;
              path = "/persist/home/${user}/.ssh/${user}-key.pub";
            } // sharedFile;
          };

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
