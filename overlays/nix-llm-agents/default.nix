# @tracking: freshness
# @reason: LLM tooling from custom flake — always want latest upstream versions
# @upstream: github:dtgagnon/nix-llm-agents (or wherever this input points)
{ inputs, ... }: _final: prev: {
  inherit (inputs.nix-llm-agents.packages.${prev.stdenv.hostPlatform.system})
    backlog-md
    claude-code
    claude-code-router
    # gemini-cli
    codex
    ;
}
