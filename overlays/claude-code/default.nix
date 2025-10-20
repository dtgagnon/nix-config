{ channels, ... }: _: prev:
{
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "2.0.20";
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-NF6uP+TGgt89iHYUHzIDW7KJgmPOWkBuduHXTMsT9gE=";
    };
  });
}
