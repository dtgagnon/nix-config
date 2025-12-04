{ inputs, ... }: _final: prev: {
  inherit (inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system})
    backlog-md
    claude-code
    claude-code-router
    gemini-cli
    codex
    ;
}
