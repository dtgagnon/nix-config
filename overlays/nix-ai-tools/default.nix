{ inputs, ... }: final: prev:
{
  inherit (inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system}) backlog-md claude-code claude-code-router opencode gemini-cli codex;

  # Use patched version with --quick-input support for Wayland/Hyprland
  claude-desktop = final.callPackage ../../packages/claude-desktop-patched {
    claude-desktop = inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system}.claude-desktop;
  };
}
