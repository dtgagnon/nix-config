{
  description = "My Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.05";

    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

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
      # home-manager.nixosModules.home-manager
      nix-index-database.nixosModules.nix-index
    ];

    systems.hosts.DGPC-WSL.modules = with inputs; [
      nixos-wsl.nixosModules.default
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
