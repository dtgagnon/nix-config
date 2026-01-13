{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.cli.claude-code;

  userGuidanceContent = ''
    - Never include attributions to claude in git commit messages
    - ## Collaboration Guidelines
    - **Challenge and question**: Don't immediately agree or proceed with requests that seem suboptimal, unclear, or potentially problematic
    - **Push back constructively**: If a proposed approach has issues, suggest better alternatives with clear rationale
    - **Think critically**: Consider edge cases, performance implications, maintainability, and best practices before implementing
    - **Seek clarification**: Ask follow-up questions when requirements are ambiguous or could be interpreted multiple ways
    - **Propose improvements**: Suggest better patterns, more robust solutions, or cleaner implementations when appropriate
    - **Be a thoughtful collaborator**: Act as a good teammate who helps improve the overall quality and direction of the project
    - Always run /codex /codex-build /gemini /gemini-build slash commands in background bashes
    - ALWAYS manage packages declaratively through flake.nix and home-manager modules. ALWAYS use `nix shell`/`nix run` for temporary needs. NEVER use `nix-env` or `nix-channel` commands - they bypass flake lock files, create untracked state, and break reproducibility.
    - Never use old nix command syntax (`nix-*`) unless absolutely necessary. Prefer new syntax intended to work with nix flakes (`nix *`).
    - If a command is not available in the current directory's environment, use the `comma` CLI tool to run it directly from nixpkgs: `, <command>` (e.g., `, htop` or `, jq --help`). This automatically fetches and runs the package without installing it.

    ## New Project Setup Requirements

    When starting ANY new coding project, ALWAYS set up the following foundational infrastructure:

    1. **Flake (`flake.nix`)**: Create a Nix flake to define:
       - Project dependencies and development tools
       - Build outputs (packages, apps, etc.)
       - Development shells with all required tooling
       - Locked dependency versions for reproducibility

    2. **Direnv (`.envrc`)**: Configure direnv integration:
       - Add `use flake` to automatically load the dev shell when entering the directory
       - Ensures consistent environment for all developers
       - Eliminates "works on my machine" issues

    3. **Development Shell**: Define comprehensive `devShells` in a shell.nix file:
       - Language-specific toolchains (compilers, interpreters, etc.)
       - Build tools and package managers
       - Formatters, linters, and LSP servers
       - Project-specific CLI tools and utilities
       - Shell hooks for automatic setup (environment variables, initialization scripts)
       Import any `devShells` into the flake.

    **This is MANDATORY for all new projects** - no exceptions. These three components ensure reproducible, isolated development environments that work consistently across machines and over time.
  '';
in
{
  # Placeholder for future declarative CLAUDE.md management
  # config = mkIf cfg.enable {
  #   home.file.".claude/CLAUDE.md".text = userGuidanceContent;
  # };
}
