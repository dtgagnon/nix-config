---
name: dev-setup
description: Initialize development project with Nix flake, direnv, devShell, and LSP configuration
---

# Development Project Setup

Set up a complete Nix-based development environment for any new project. This creates reproducible, isolated environments with full LSP support.

## Required Components

Every new project MUST have these four components:

1. **`flake.nix`** - Project dependencies, build outputs, and dev shells
2. **`.envrc`** - Direnv integration for automatic shell loading
3. **`shell.nix`** - Development shell with all tooling
4. **`.claude/settings.local.json`** - LSP configuration for Claude Code

## Usage

When the user asks to set up a new project or initialize a development environment, create all four files based on the project type.

## Step 1: Identify Project Type

Ask the user or detect from existing files:
- **Nix**: Pure Nix project (modules, packages, configs)
- **Python**: Python application or library
- **Node/TypeScript**: JavaScript/TypeScript project
- **Rust**: Rust application or library
- **Go**: Go application or module
- **Multi-language**: Combination of the above

## Step 2: Create flake.nix

### Minimal Template (Pure Nix)

```nix
{
  description = "Project description";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.''${system};
      in
      {
        devShells.default = import ./shell.nix { inherit pkgs; };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
```

### Python Template

```nix
{
  description = "Python project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.''${system};
        python = pkgs.python312;
        pythonPackages = python.pkgs;
      in
      {
        devShells.default = import ./shell.nix { inherit pkgs python pythonPackages; };

        packages.default = pythonPackages.buildPythonApplication {
          pname = "project-name";
          version = "0.1.0";
          src = ./.;
          # dependencies...
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
```

### Node/TypeScript Template

```nix
{
  description = "TypeScript project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.''${system};
      in
      {
        devShells.default = import ./shell.nix { inherit pkgs; };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
```

### Rust Template

```nix
{
  description = "Rust project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };
      in
      {
        devShells.default = import ./shell.nix { inherit pkgs rust; };

        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "project-name";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
```

### Go Template

```nix
{
  description = "Go project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.''${system};
      in
      {
        devShells.default = import ./shell.nix { inherit pkgs; };

        packages.default = pkgs.buildGoModule {
          pname = "project-name";
          version = "0.1.0";
          src = ./.;
          vendorHash = null; # or specific hash
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
```

## Step 3: Create shell.nix

### Pure Nix Shell

```nix
{ pkgs }:

pkgs.mkShell {
  name = "project-dev";

  packages = with pkgs; [
    # Nix tooling
    nixd
    nixfmt-rfc-style
    nil
    nix-diff

    # General utilities
    git
    jq
  ];

  shellHook = '''
    echo "Development environment loaded"
  '
