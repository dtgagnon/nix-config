{
  description = "SPIRE FLAKE";

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
          # neovim.overlays.default
          nix-topology.overlays.default
          nur.overlays.default
          # proxmox-nixos.overlays.x86_64-linux #NOTE Not in use - can remove
          odooAdds.overlays.default
          mcp-servers-nix.overlays.default
          n8n-private.overlays.default
          nix-bookshelf.overlays.default
        ];

        systems.modules.nixos = with inputs; [
          authentik.nixosModules.default
          copyparty.nixosModules.default
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          nix-index-database.nixosModules.nix-index
          nix-topology.nixosModules.default
          NixVirt.nixosModules.default
          preservation.nixosModules.preservation
          rybbix.nixosModules.default
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
        ];

        systems.modules.darwin = with inputs; [
          home-manager.darwinModules.home-manager
          nix-index-database.darwinModules.nix-index
          sops-nix.darwinModules.sops
          stylix.darwinModules.stylix
        ];

        systems.hosts."DG-PC".modules = with inputs; [
          hyprland.nixosModules.default
        ];

        systems.hosts.spirepoint.modules = with inputs; [
          proxmox-nixos.nixosModules.proxmox-ve
          nixarr.nixosModules.default
        ];

        systems.hosts.slim.modules = with inputs; [
          microvm.nixosModules.host
        ];

        systems.hosts.oranix.modules = with inputs; [
          spirenet-dashboard.nixosModules.default
        ];

        homes.packages = with inputs; [
          # zen-browser package is now provided by the home-manager module
        ];

        homes.modules = with inputs; [
          ags.homeManagerModules.default
          emma.homeManagerModules.default
          noctalia.homeModules.default
          sops-nix.homeManagerModules.sops
          stylix.homeModules.stylix
          zen-browser.homeModules.twilight
        ];

        deploy = lib.mkDeploy {
          inherit (inputs) self;
          overrides = import ./deployments;
        };

        outputs-builder = channels: {
          formatter = channels.nixpkgs.nixfmt;
          packages = {
            mcp-mxroute = channels.nixpkgs.callPackage ./packages/mcp-servers/mcp-mxroute { };
            mcp-libreoffice = channels.nixpkgs.callPackage ./packages/mcp-servers/mcp-libreoffice { };
          };
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
          aiderProj.description = "Development environment flake template w/ aider";
          devFlake.description = "General development environment flake template";
          sysMod.description = "NixOS snowfall system module template";
          homeMod.description = "NixOS snowfall home-manager module template";
        };
      }
    // { self = inputs.self; };

  inputs = {
    ## packages
    stablepkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    masterpkgs.url = "github:nixos/nixpkgs/master";
    nur.url = "github:nix-community/NUR"; # Community package repository

    ## configuration frameworks
    snowfall-lib.url = "github:dtgagnon/snowfall-lib"; # based on updates from "github:anntnzrb/snowfall-lib"
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
    preservation.url = "github:nix-community/preservation"; #TODO: Replace impermanence w/ preservation.

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "stablepkgs";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    # NOTE Re-enable if using WSL
    # nixos-wsl.url = "github:nix-community/nixos-wsl";
    # nixos-wsl.inputs.nixpkgs.follows = "stablepkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

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
    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";

    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    NixVirt.url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    NixVirt.inputs.nixpkgs.follows = "nixpkgs";

    nixos-vfio.url = "github:j-brn/nixos-vfio";
    nixos-vfio.inputs.nixpkgs.follows = "nixpkgs";

    ## applications+services
    authentik.url = "github:nix-community/authentik-nix";
    copyparty.url = "github:9001/copyparty";
    copyparty.inputs.nixpkgs.follows = "nixpkgs";

    ghostty.url = "github:ghostty-org/ghostty";
    ghostty.inputs.nixpkgs.follows = "nixpkgs";

    spirenixvim.url = "github:dtgagnon/nixvim/refactor/to-blueprint";

    nixarr.url = "github:rasmus-kirk/nixarr";

    rybbix.url = "github:dtgagnon/rybbix";

    opencode.url = "github:sst/opencode";

    zen-browser.url = "github:0xc000022070/zen-browser-flake/beta";

    ## desktop
    aquamarine = {
      url = "github:dtgagnon/aquamarine/fix/readbuffer-preserve-alive-attachments";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.aquamarine.follows = "aquamarine";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";

    # Experimental: Hyprland Remote Desktop PRs (for RustDesk/remote desktop support)
    experimental-hyprland-rdp.url = "github:3l0w/Hyprland/feat/input-capture-impl";
    experimental-hyprland-rdp.inputs.nixpkgs.follows = "nixpkgs";
    experimental-xdph-rdp.url = "github:toneengo/xdg-desktop-portal-hyprland/feat/remote-desktop-impl";
    experimental-xdph-rdp.inputs.nixpkgs.follows = "nixpkgs";

    quickshell.url = "github:quickshell-mirror/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";
    # stylix.url = "github:nix-community/stylix/0c32a193b72d9461b4041737fc56c86b4e4e9d10";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    ## programming langs/lsps
    astal.url = "github:Aylur/astal";
    astal.inputs.nixpkgs.follows = "nixpkgs";
    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    nixd.url = "github:nix-community/nixd";

    nix-bookshelf.url = "github:dtgagnon/nix-bookshelf";
    nix-bookshelf.inputs.nixpkgs.follows = "nixpkgs";

    ## custom repos
    n8n-private.url = "git+ssh://git@github.com/dtgagnon/n8n-nix-overlay";
    odooAdds.url = "git+ssh://git@github.com/dtgagnon/odooAdds";
    yell.url = "git+ssh://git@github.com/dtgagnon/yell";
    yell.inputs.nixpkgs.follows = "nixpkgs";
    emma.url = "git+ssh://git@github.com/dtgagnon/emma";

    ## websites
    dtge.url = "git+ssh://git@github.com/dtgagnon/dtg-engineering";
    eterna-design.url = "git+ssh://git@github.com/dtgagnon/eterna-design";
    portfolio.url = "git+ssh://git@github.com/dtgagnon/web-portfolio";
    spirenet-dashboard.url = "git+ssh://git@github.com/dtgagnon/spirenet-dashboard";

    ## ai tools
    nix-llm-agents.url = "github:numtide/llm-agents.nix";
    ### mcp servers
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
}
