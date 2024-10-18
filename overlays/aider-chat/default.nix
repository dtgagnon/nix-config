final: prev:
let
  version = "0.57.0";
in
{
  aider-chat = prev.aider-chat.overrideAttrs (oldAttrs: {
    pythonRelaxDeps = false;

    src = {
      rev = "refs/tags/v${version}";
      hash = "sha256-ErDepSju8B4GochHKxL03aUfOLAiNfTaXBAllAZ144M=";
    };
  });
}
