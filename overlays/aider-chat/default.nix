{ channels, ... }: _final: prev:
{
  aider-chat = prev.aider-chat.overrideAttrs (oldAttrs: rec {
    python3 = oldAttrs.python3.override {
      packageOverrides = self: super:
        let
          baseOverrides = oldAttrs.python3.packageOverrides self super;
        in
        baseOverrides // {
          llama-index-core = channels.stablepkgs.pythonPackages.llama-index-core;
          llama-index-embeddings-huggingface = channels.stablepkgs.pythonPackages.llama-index-embeddings-huggingface;
        };
    };
  });
}
