{ inputs, ... }: _final: prev: {
  inherit (inputs.nix-llm-agents.packages.${prev.stdenv.hostPlatform.system})
    backlog-md
    claude-code
    claude-code-router
    # gemini-cli
    codex
    ;
}
