{ inputs, ... }:
final: prev: {
  inherit (inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system})
    backlog-md
    claude-code
    claude-code-router
    gemini-cli
    codex
    ;

  # Override opencode to fix node_modules hash mismatch
  # opencode =
  #   inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system}.opencode.overrideAttrs
  #     (oldAttrs: {
  #       node_modules = oldAttrs.node_modules.overrideAttrs (oldNodeAttrs: {
  #         outputHash = "sha256-X1RMD8LFqHEnmlXvT1UJ3eYe/yDjCKf7ryNzJE7n6Kk=";
  #       });
  #     });
}
