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
let cfg = config.${namespace}.nix;
in {
  options.${namespace}.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt package pkgs.nix "Which nix package to use.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nixfmt-classic
      nix-index
      nix-prefetch-git
      nix-output-monitor
    ];

    # We disable this because it's hook is not compatible with nix-index.
    programs.command-not-found = disabled;

    nix =
      let
        user = config.${namespace}.user.name;
        users = [ "root" user ] ++ optional config.services.hydra.enable "hydra";
        isHomeManagerDirenvEnabled = config.home-manager.users.${user}.${namespace}.tools.direnv.enable;
      
      in {
        package = cfg.package;

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };

        settings = {
            experimental-features = "nix-command flakes";
            http-connections = 50;
            warn-dirty = false;
            log-lines = 50;
            sandbox = "relaxed";
            auto-optimise-store = true;
            trusted-users = users;
            allowed-users = users;
          } // (optionalAttrs isHomeManagerDirenvEnabled {
            keep-outputs = true;
            keep-derivations = true;
          });


        # flake-utils-plus
        generateRegistryFromInputs = true;
        generateNixPathFromInputs = true;
        linkInputs = true;
      };
  };
}