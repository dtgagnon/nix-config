{ inputs, ... }: _: prev:
{
  inherit (inputs.nix-ai-tools.packages.${prev.system}) backlog-md claude-code claude-code-router claude-desktop opencode gemini-cli codex;
}
