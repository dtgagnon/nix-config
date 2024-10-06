{
  description = "My Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    snowfall-lib.url = "github:snowfallorg/lib?ref=v3.0.3";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "unstable";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    cowsay.url = "github:snowfallorg/cowsay?ref=v1.3.0";
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
        namespace = "sn";
      };
    };
  in 

  lib.mkFlake {
    channels-config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-25.9.0"
        "electron-27.3.11"
      ];
    };
    
    homes.modules = with inputs; [
      nix-index-database.hmModules.nix-index
    ];

    systems.modules.nixos = with inputs; [
      home-manager.nixosModules.home-manager
      nix-index-database.nixosModules.nix-index
    ];

    systems.hosts.DGPC-WSL.modules = with inputs; [
      nixos-wsl.nixosModules.default
    ];

    templates = {
      empty.description = "A Nix Flake using snowfall-lib";
      sysMod.description = "template for NixOS system modules.";
      homeMod.description = "template for home-manager modules.";
      homeUser.description = "A template for setting up home-manager users.";
    };
  };
}
