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
let cfg = config.${namespace}.user;
in {
  options.${namespace}.user = with types; {
    name = mkOpt str 
      "dtgagnon" "The name to use for the user account.";
    fullName = mkOpt str 
      "Derek Gagnon" "The full name of the user.";
    email = mkOpt str 
      "gagnon.derek@gmail.com" "The email of the user.";
    initialPassword = mkOpt str 
      "password" "The initial password for the user account.";

    prompt-init = mkBoolOpt true "Whether or not to show an initial message when opening a new shell.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } (mdDoc "Extra options passed to `users.users.<name>`.");
  };

  config = {
    # Configure the default shell for users.
    programs.zsh = {
      enable = true;
    };

    sn.home = {
      extraOptions = {
        programs.starship = {
          enable = true;
          settings = {
            character = {
              success_symbol = "[➜](bold green)";
              error_symbol = "[✗](bold red) ";
              vicmd_symbol = "[](bold blue) ";
            };
          };
        };

        programs.zsh = {
          enable = true;
          autosuggestion = enabled;
          syntaxHighlighting = enabled;
        };
      };
    };


    users.users.${cfg.name} = {
      inherit (cfg) name initialPassword;

      home = "/home/${cfg.name}";
      group = "users";
      shell = pkgs.zsh;

      extraGroups = cfg.extraGroups;

      isNormalUser = true; # If false, the user is treated as a 'system user'.
    } // cfg.extraOptions;
  };
}
