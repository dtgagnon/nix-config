---
name: dev-setup
description: Initialize development project with Nix flake, direnv, devShell, and LSP configuration
---

# Development Project Setup

Create reproducible, isolated Nix development environments with LSP support.

## Required Files

1. `flake.nix` - Dependencies, outputs, dev shells
2. `.envrc` - Contains `use flake` for direnv
3. `shell.nix` - Dev shell with tooling
4. `.claude/settings.local.json` - LSP config

## flake.nix Template

```nix
{
  description = "Project description";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Rust projects only:
    # rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Python projects:
        # python = pkgs.python312;
        # pythonPackages = python.pkgs;

        # Rust projects (requires rust-overlay input):
        # overlays = [ (import inputs.rust-overlay) ];
        # pkgs = import nixpkgs { inherit system overlays; };
        # rust = pkgs.rust-bin.stable.latest.default.override {
        #   extensions = [ "rust-src" "rust-analyzer" ];
        # };

      in {
        devShells.default = import ./shell.nix { inherit pkgs; };
        # Python: { inherit pkgs python pythonPackages; }
        # Rust: { inherit pkgs rust; }

        # Optional package output:
        # packages.default = pythonPackages.buildPythonApplication { ... };
        # packages.default = pkgs.rustPlatform.buildRustPackage { ... };
        # packages.default = pkgs.buildGoModule { vendorHash = null; ... };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
```

## shell.nix Template

```nix
{ pkgs
# Python: , python, pythonPackages
# Rust: , rust
}:

pkgs.mkShell {
  name = "project-dev";

  packages = with pkgs; [
    # Always include
    git

    # Nix projects
    nixd
    nixfmt-rfc-style

    # Python projects
    # python
    # pythonPackages.pip
    # pythonPackages.pytest
    # pyright

    # Node/TypeScript projects
    # nodejs
    # pnpm
    # typescript
    # typescript-language-server

    # Rust projects
    # rust  # from flake let bindings
    # cargo-watch

    # Go projects
    # go
    # gopls
    # gotools
  ];
}
```

## .claude/settings.local.json

```json
{
  "lspServers": {
    "nix": { "command": "nixd" },
    "python": { "command": "pyright-langserver", "args": ["--stdio"] },
    "typescript": { "command": "typescript-language-server", "args": ["--stdio"] },
    "rust": { "command": "rust-analyzer" },
    "go": { "command": "gopls" }
  }
}
```

Include only the LSPs relevant to your project.
