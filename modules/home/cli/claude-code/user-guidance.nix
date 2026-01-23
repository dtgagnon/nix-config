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

    When starting ANY new coding project, ALWAYS use the `/dev-setup` skill to set up the development environment. This skill handles all foundational infrastructure automatically.

    The following components are MANDATORY for all new projects:
    1. **Flake (`flake.nix`)**: Project dependencies, build outputs, dev shells, locked versions
    2. **Direnv (`.envrc`)**: Auto-load dev shell with `use flake`
    3. **Development Shell (`shell.nix`)**: Toolchains, formatters, linters, LSPs (always include `nixd` for Nix projects)
    4. **Claude Code LSP (`.claude/settings.local.json`)**: LSP server config pointing to devShell binaries

    **ALWAYS run `/dev-setup` first** - it ensures reproducible, isolated development environments with full LSP support.
  '';
in
{
  # Placeholder for future declarative CLAUDE.md management
  # config = mkIf cfg.enable {
  #   home.file.".claude/CLAUDE.md".text = userGuidanceContent;
  # };
}
