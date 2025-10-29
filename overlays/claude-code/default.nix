{ channels, ... }: _: prev:
{
  inherit (channels.masterpkgs) claude-code;
  # claude-code = prev.claude-code.overrideAttrs (_oldAttrs: rec {
  #   version = "2.0.27";
  #   src = prev.fetchurl {
  #     url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
  #     hash = "sha256-ZxwEnUWCtgrGhgtUjcWcMgLqzaajwE3pG7iSIfaS3ic=";
  #   };
  #
  #   npmDepsHash = "";
  # });
}
