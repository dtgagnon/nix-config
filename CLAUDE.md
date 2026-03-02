# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a NixOS flake-based configuration using **Snowfall Lib** as the structural framework. Key architectural points:

- **Namespace**: `spirenix` - all custom modules/packages are namespaced under this
- **Snowfall conventions**: The flake uses snowfall-lib which provides automatic discovery of modules, packages, and systems based on directory structure
- **Multi-platform**: Supports x86_64-linux (NixOS) and WSL2
- **Modular design**: Heavy use of NixOS/home-manager modules with options for composability

### Directory Structure

- `systems/x86_64-linux/<HOST>/` - NixOS system configurations (hardware + system-level settings)
- `homes/x86_64-linux/<user>@<host>/` - Home Manager user configurations
- `modules/nixos/` - System-level NixOS modules (services, hardware, security)
- `modules/home/` - Home Manager modules (apps, desktop, CLI tools)
- `packages/` - Custom package definitions
- `overlays/` - Package overlays and modifications
- `lib/` - Helper functions (deploy, module utilities, nixvim helpers, nix-rice extensions)
- `templates/` - Flake templates for development environments
- `shells/` - Development shell configurations

### Key Flake Inputs

- **snowfall-lib**: Provides the structural framework and conventions
- **home-manager**: User-level configuration
- **disko**: Declarative disk partitioning (luks + lvm + btrfs)
- **impermanence/preservation**: Root filesystem management (only explicitly declared files persist)
- **sops-nix**: Secrets management
- **stylix**: System-wide theming
- **hyprland**: Wayland compositor
- **nix-secrets**: Private flake input for secrets (separate git repo)

Note: Darwin configurations were removed in January 2025

## Build & Development Commands

### Verifying Changes

Use targeted `nix eval` for quick validation (catches syntax/type/option errors without building):

```bash
# Evaluating a package
nix eval .#packages.x86_64-linux.<package-name> --apply 'x: "ok"'

# Evaluating a NixOS system configuration (for module changes)
nix eval .#nixosConfigurations.<HOST>.config.system.build.toplevel --apply 'x: "ok"'

# Evaluating a home-manager configuration
nix eval .#homeConfigurations."<user>@<host>".activationPackage --apply 'x: "ok"'

# Build a specific package when ready to test actual compilation
nix build .#<package-name>

# Format all Nix files with nixfmt-rfc-style
nix fmt
```

**Important**: Do NOT use `nix flake check` - it evaluates ALL outputs which is extremely slow for mono-flakes. Target only what you're working on.

### Deploying (affects live system)

```bash
# Test system configuration (builds and activates, but doesn't add to boot menu)
nixos-rebuild test --sudo --flake .#<HOST>

# Build and activate system configuration (adds to boot menu)
nixos-rebuild switch --sudo --flake .#<HOST>

# Update all flake inputs
nix flake update
```

**Note**: Avoid `nixos-rebuild` commands when just testing changes - they modify the live environment. Use `nix eval` and `nix build` for verification instead.

### Just Recipes (Remote Deployment Focus)

The `justfile` exists primarily for **remote installation and secret management workflows**, not day-to-day development. Key recipes:

```bash
# Build system (runs scripts/system-flake-rebuild.sh)
just rebuild

# Update flake and rebuild
just rebuild-update

# Build ISO installer
just iso

# Check sops secrets configuration
just check-sops

# Update flake.lock for nix-secrets input
just update-nix-secrets
```

**Important**: `just` recipes handle sops secret updates and remote sync workflows. For local development, prefer direct `nixos-rebuild` and `nix` commands.

**Note**: `just` recipes are designed specifically for remote installation automation and secret management workflows. For local development, always use direct `nixos-rebuild` and `nix` commands instead.

### Development Shell

```bash
# Enter development shell with Nushell
nix develop --command nushell
```

## Secrets Management (sops-nix)

- Secrets live in a separate **private git repository** referenced by the `nix-secrets` flake input
- Secret files are encrypted with age keys (host and user keys)
- Never commit unencrypted secrets or `.sops.yaml` files to this public repo
- Use `scripts/check-sops.sh` to verify secrets are properly configured
- The `justfile` has extensive recipes for managing sops keys and creation rules (see lines 77-135)

## Module System Patterns

### Creating System Modules

System modules go in `modules/nixos/<category>/` and use Snowfall's automatic discovery. Example structure:

```nix
{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.spirenix.<category>.<module-name>;
in
{
  options.spirenix.<category>.<module-name> = {
    enable = mkEnableOption "description";
    # other options...
  };

  config = mkIf cfg.enable {
    # implementation
  };
}
```

### Creating Home Manager Modules

Home modules go in `modules/home/<category>/` following the same pattern but under `home-manager` config space.

### Host Configuration

Host configs in `systems/x86_64-linux/<HOST>/default.nix` import modules and set host-specific options. Hardware configuration typically in `hardware.nix` alongside.

### Home Configuration

Home configs in `homes/x86_64-linux/<user>@<host>/default.nix` enable home-manager modules and set user preferences.

## Naming Conventions

- Modules: `lower-kebab-case`
- Hosts: Match actual hostname exactly (e.g., `DG-PC`, `spirepoint`, `slim`)
- Homes: `<username>@<hostname>` format
- Files: `default.nix` for main module, `<descriptive-name>.nix` for specific functionality

## Formatter

The flake uses `nixfmt-rfc-style` as the formatter. Always run `nix fmt` before committing changes.

## Testing Guidelines

Before opening a PR:
- Use `nix eval` to validate affected configurations (see "Verifying Changes" above)
- Use `nix build` if testing specific package builds
- Desktop/UI changes: attach a screenshot and list affected host(s) in the PR description

## Commit & Pull Request Guidelines

### Commit Messages
Use Conventional Commits format:
- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code restructuring
- `chore:` - Maintenance tasks
- `docs:` - Documentation updates

Add scope when helpful: `fix(waybar): correct battery icon`

### Pull Requests
- Provide clear description of changes
- Link related issues
- List impacted hosts
- Ensure all checks pass
- Include screenshots for visual/desktop changes
- Keep `flake.lock` updates isolated in separate commits or clearly noted

## Special Considerations

### Snowfall Auto-Discovery

Snowfall automatically discovers and imports:
- System configurations from `systems/`
- Home configurations from `homes/`
- Modules from `modules/{nixos,home}/`
- Packages from `packages/`
- Overlays from `overlays/`

You generally don't need explicit imports in `flake.nix` for these.

### Host-Specific Modules

Some hosts have additional modules injected in `flake.nix`:
- `DG-PC`: hyprland.nixosModules.default
- `spirepoint`: proxmox-nixos, nixarr modules
- `DGPC-WSL`: nixos-wsl.nixosModules.default

### Permitted Insecure Packages

The flake currently permits specific insecure packages (see `flake.nix` lines 26-31) for Sonarr compatibility. Document any additions with reasoning.

## Current Hosts

- **DG-PC**: Main desktop (MSI Z790, i7-13700K, 64GB RAM, RTX 4090 w/ VFIO passthrough, Samsung Odyssey Neo G9 57" 7680x2160@240Hz, Hyprland)
- **spirepoint**: Server (Proxmox VM, nixarr media stack, 16GB RAM, GTX 1050 Ti)
- **slim**: Laptop (Asus Zenbook, minimal config)
- **oranix**: Oracle cloud instance
- **generic**: Generic system template

## User Environment Preferences

- **Shell**: Nushell (with vi mode)
- **Terminal**: Ghostty
- **Editor**: Neovim (custom nixvim config from spirenixvim flake input)
- **File Manager**: Yazi
- **WM**: Hyprland (with custom keybinds)
- **Theme**: Stylix with dynamic dark theme
- **Common CLI tools**: bat, eza, fzf, zoxide, direnv, broot
- Never use "... or false" in nix configurations. It is unnecessary.

## Recent Migrations & TODOs

### Completed Migrations
- **January 2025**: Removed all Darwin (macOS) configurations (commit 10a5fd3)
- **Neovim architecture**: Migrated from overlay-based approach to direct `spirenixvim` flake input
- **fd binary references**: Updated fzf and Nushell configs to use explicit `getExe fd` instead of PATH lookup

### In Progress
- **Persistence framework**: Migrating from `impermanence` to `preservation` (TODO in flake.nix)

### Notes
- Neovim is now consumed via `inputs.spirenixvim.packages.${system}` rather than overlay
- Antigravity's `argv.json` is now managed via activation script instead of static file
