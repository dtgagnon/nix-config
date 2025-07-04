{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib)
    mkIf
    types
    optional
    optionalAttrs
    ;
  inherit (lib.${namespace}) mkOpt mkBoolOpt disabled;
  cfg = config.${namespace}.nix;
in
{
  options.${namespace}.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt package pkgs.nix "Which nix package to use.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      deploy-rs
      nixfmt-rfc-style
      nix-index
      nix-prefetch-git
      nix-output-monitor
    ];

    # We disable this because it's hook is not compatible with nix-index.
    programs.command-not-found = disabled;

    nix =
      let
        user = config.${namespace}.user.name;
        # allUsers = lib.attrNames (lib.filterAttrs (n: v: v.isNormalUser) config.users.users);
        users = [ "root" "dtgagnon" ] /* ++ allUsers */ ++ optional config.services.hydra.enable "hydra";

        isHomeManagerDirenvEnabled =
          if config.home-manager.users ? ${user}
          then config.home-manager.users.${user}.${namespace}.cli.direnv.enable
          else false;
      in
      {
        package = cfg.package;

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };

        settings = {
          experimental-features = lib.mkDefault "nix-command flakes pipe-operators";
          allowed-uris = [ "ssh://git@github.com" ];
          http-connections = 50;
          warn-dirty = false;
          log-lines = 50;
          sandbox = "relaxed";
          auto-optimise-store = true;
          trusted-users = users;
          allowed-users = users;
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
          ];
          trusted-substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
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
