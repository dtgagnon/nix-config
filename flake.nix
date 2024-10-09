{
  description = "My Nix flake";

  inputs = {
    ## packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.05";

    ## configuration
    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    ## security
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    ## config deployments
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    ## Utilities
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";

    nix-ld.url = "github:nix-community/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    ## miscellaneous
    cowsay.url = "github:snowfallorg/cowsay";
  };

  outputs = inputs:
  let
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;
      snowfall = {
        meta = {
          name = "spirenix";
          title = "SpireNix Namespace";
        };
        namespace = "spirenix";
      };
    };
  in 

  lib.mkFlake {
    inherit inputs;
    src = ./.;

    channels-config = {
      allowUnfree = true;
      permittedInsecurePackages = [  ];
    };
    

    systems.modules.nixos = with inputs; [
      home-manager.nixosModules.home-manager
      nix-index-database.nixosModules.nix-index
      sops-nix.nixosModules.sops
    ];

    systems.hosts.DGPC-WSL.modules = with inputs; [
      nixos-wsl.nixosModules.default
      nix-ld.nixosModules.nix-ld
    ];

    homes.modules = with inputs; [ 
      nix-index-database.hmModules.nix-index
    ];

    templates = {
      empty.description = "A Nix Flake using snowfall-lib";
      sysMod.description = "template for NixOS system modules.";
      homeMod.description = "template for home-manager modules.";
      homeUser.description = "A template for setting up home-manager users.";
    };
  };
}
