{
  description = "Minimal NixOS Installer Flake";

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          meta = {
            name = "NixOS-Installer";
            title = "NixOS Installer Flake Namespace";
          };
          namespace = "installer";
        };
      };
    in
    lib.mkFlake
      {
        inherit inputs;
        src = ../.; # maybe make this point to a directory

        systems.hosts.minimal.modules = with inputs; [
          disko.nixosModules
          home-manager.nixosModules.home-manager
        ];
      }
    // { self = inputs.self; };

  inputs = {
    # nix packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    # flake framework
    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    # disko partitioning and declaration
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    ## security
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "stablepkgs";
    nix-secrets = {
      url = "git+ssh://git@github.com/dtgagnon/nix-secrets.git";
      flake = false;
    };
  };
}
