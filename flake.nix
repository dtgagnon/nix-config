{
  description = "SPIRE FLAKE";

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
          permittedInsecurePackages = [
            # Below 4 for sonarr until they update to .NET 8
            "aspnetcore-runtime-6.0.36"
            "aspnetcore-runtime-wrapped-6.0.36"
            "dotnet-sdk-6.0.428"
            "dotnet-sdk-wrapped-6.0.428"
          ];
        };

        alias = {
          shells.default = "flake";
        };

        overlays = with inputs; [
          neovim.overlays.default
          nix-topology.overlays.default
          nur.overlays.default
          proxmox-nixos.overlays.x86_64-linux
        ];

        systems.modules.nixos = with inputs; [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          nix-index-database.nixosModules.nix-index
          nix-topology.nixosModules.default
          NixVirt.nixosModules.default
          plane.nixosModules.default
          preservation.nixosModules.preservation
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
        ];

        systems.hosts.DG-PC.modules = with inputs; [

        ];

        systems.hosts.spirepoint.modules = with inputs; [
          proxmox-nixos.nixosModules.proxmox-ve
          nixarr.nixosModules.default
        ];

        systems.hosts.DGPC-WSL.modules = with inputs; [
          nixos-wsl.nixosModules.default
        ];

        homes.packages = with inputs; [
          zen-browser.packages.twilight
        ];

        homes.modules = with inputs; [
          ags.homeManagerModules.default
          hyprpanel.homeManagerModules.hyprpanel
          sops-nix.homeManagerModules.sops
          stylix.homeModules.stylix
        ];

        deploy = lib.mkDeploy { inherit (inputs) self; };

        outputs-builder = channels: {
          formatter = channels.nixpkgs.nixfmt-rfc-style;
        };

        # topology = with inputs;
        #   let
        #     host = self.nixosConfigurations.${builtins.head (builtins.attrNames self.nixosConfigurations)};
        #   in
        #   import nix-topology {
        #     inherit (host) pkgs;
        #     modules = [
        #       (import ./topology { inherit (host) config; })
        #       { nixosConfigurations = builtins.mapAttrs (
        #         name: value:
        #           if builtins.hasAttr "kvm" (value.config or {})
        #           then null
        #           else value
        #       ) self.nixosConfigurations; }
        #     ];
        #   };

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

  inputs = {
    ## packages
    stablepkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    masterpkgs.url = "github:nixos/nixpkgs/master";
    nur.url = "github:nix-community/NUR"; # Community package repository

    ## configuration frameworks
    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
    preservation.url = "github:nix-community/preservation"; #TODO: Replace impermanence w/ preservation.

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


    ## virtualisation
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    NixVirt.url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";

    nixos-vfio.url = "github:j-brn/nixos-vfio";
    nixos-vfio.inputs.nixpkgs.follows = "nixpkgs";

    ## applications+services
    ghostty.url = "github:ghostty-org/ghostty/7f9bb3c0e54f585e11259bc0c9064813d061929c"; #TODO: re-pin the main flake once they fix the esc:caps key issue

    neovim.url = "github:dtgagnon/nixvim/main";

    nixarr.url = "github:rasmus-kirk/nixarr";

    nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
    nixos-conf-editor.inputs.nixpkgs.follows = "nixpkgs";

    plane.url = "github:dtgagnon/plane/add/nix";
    plane.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    ## desktop
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.nixpkgs.follows = "hyprland";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    ## programming langs/lsps
    astal.url = "github:Aylur/astal";
    astal.inputs.nixpkgs.follows = "nixpkgs";
    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    nixd.url = "github:nix-community/nixd";
  };
}
