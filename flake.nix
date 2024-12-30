{
  description = "SPIRE FLAKE";

  inputs = {
    ## packages
    stablepkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    masterpkgs.url = "github:nixos/nixpkgs/master";
    nur.url = "github:nix-community/NUR"; # Community package repository

    ## configuration frameworks
    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "stablepkgs";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "stablepkgs";

    ## libraries
    nix-rice.url = "github:bertof/nix-rice";
    nix-rice.inputs.nixpkgs.follows = "nixpkgs";

    ## security
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "stablepkgs";
    nix-secrets = {
      url = "git+ssh://git@github.com/dtgagnon/nix-secrets.git";
      flake = false;
    };

    ## deployment utilities
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    ## utilities
    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";

    ## virtualisation
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    NixVirt.url = "https://flakehub.com/f/AshleyYakeley/NixVirt/0.5.0.tar.gz";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";

    ## applications
    ghostty.url = "github:ghostty-org/ghostty"; #NOTE: flake is already following nixos-unstable and 24.11 where needed

    neovim.url = "github:dtgagnon/nixvim/main";
    neovim.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    ## desktop
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "stablepkgs";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.nixpkgs.follows = "hyprland";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    ## programming langs
    astal.url = "github:Aylur/astal";
    astal.inputs.nixpkgs.follows = "nixpkgs";
    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
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
          neovim.overlays.default # provides spirenix-nvim namespace from custom neovim flake
          nix-topology.overlays.default
          nur.overlays.default
          proxmox-nixos.overlays.default
        ];

        homes.packages = with inputs; [
          zen-browser.packages.specific
        ];

        systems.modules.nixos = with inputs; [
          stylix.nixosModules.stylix
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          nix-index-database.nixosModules.nix-index
          nix-topology.nixosModules.default
          NixVirt.nixosModules.default
        ];

        systems.hosts.DGPC-WSL.modules = with inputs; [
          nixos-wsl.nixosModules.default
        ];

        systems.hosts.spirepoint.modules = with inputs; [
          proxmox-nixos.nixosModules.proxmox-ve
        ];

        homes.modules = with inputs; [
          ags.homeManagerModules.default
        ];

        deploy = lib.mkDeploy { inherit (inputs) self; };

        outputs-builder = channels: {
          formatter = channels.nixpkgs.nixfmt-rfc-style;
        };

        topology =
          with inputs;
          let
            host = self.nixosConfigurations.${builtins.head (builtins.attrNames self.nixosConfigurations)};
          in
          import nix-topology {
            inherit (host) pkgs;
            modules = [
              (import ./topology { inherit (host) config; })
              { inherit (self) nixosConfigurations; }
            ];
          };

        templates = {
          empty.description = "A Nix Flake using snowfall-lib";
          tmpDevShell.description = "A placeholder for a dev environment flake structure";
          aiderProj.description = "dev-env w/ aider flake template";
          sysMod.description = "template for NixOS system modules.";
          homeMod.description = "template for home-manager modules.";
        };
      }
    // {
      self = inputs.self;
    };
}
