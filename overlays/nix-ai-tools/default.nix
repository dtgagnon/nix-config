{ inputs, ... }: final: prev:
{
  inherit (inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system}) backlog-md claude-code claude-code-router gemini-cli codex;

  # Override opencode to fix node_modules hash mismatch
  opencode = inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system}.opencode.overrideAttrs (oldAttrs: {
    node_modules = oldAttrs.node_modules.overrideAttrs (oldNodeAttrs: {
      outputHash = "sha256-Q3008o4dEZdf/4ATOmOfJIJa7B+MeLVMWzfTLVDcWjg=";
    });
  });

  # Use patched version with --quick-input support for Wayland/Hyprland
  claude-desktop = final.callPackage ../../packages/claude-desktop-patched {
    claude-desktop = inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system}.claude-desktop;
  };
}
