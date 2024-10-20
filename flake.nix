{
  description = "My Nix flake";

  inputs = {
    ## packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stablepkgs.url = "github:nixos/nixpkgs/nixos-24.05";
		devpkgs.url = "github:nixos/nixpkgs/master";

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

    ## utilities
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    ## applications
    neovim.url = "github:dtgagnon/nixvim/main";
    neovim.inputs.nixpkgs.follows = "nixpkgs";

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

    lib.mkFlake
      {
        inherit inputs;
        src = ./.;

        channels-config = {
          allowUnfree = true;
          permittedInsecurePackages = [ ];
        };

        overlays = with inputs; [
          neovim.overlays.default
        ];

        systems.modules.nixos = with inputs; [
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-index-database.nixosModules.nix-index
        ];

        systems.hosts.DGPC-WSL.modules = with inputs; [
          nixos-wsl.nixosModules.default
        ];

        homes.modules = with inputs; [
          nix-index-database.hmModules.nix-index
        ];

        deploy = lib.mkDeploy { inherit (inputs) self; };

        outputs-builder = channels: { formatter = channels.nixpkgs.nixfmt-rfc-style; };

        templates = {
          empty.description = "A Nix Flake using snowfall-lib";
          aiderProj.description = "dev-env w/ aider flake template";
          sysMod.description = "template for NixOS system modules.";
          homeMod.description = "template for home-manager modules.";
          homeUser.description = "A template for setting up home-manager users.";
        };
      } // { self = inputs.self; };
}
