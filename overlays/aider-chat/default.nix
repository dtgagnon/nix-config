_final: prev:
let
  version = "0.57.0";
in
{
  aider-chat = prev.aider-chat.overrideAttrs {
    inherit version;
    pythonRelaxDeps = false;

    src = prev.fetchFromGitHub {
      owner = "paul-gauthier";
      repo = "aider";
      rev = "refs/tags/v${version}";
      hash = "sha256-ErDepSju8B4GochHKxL03aUfOLAiNfTaXBAllAZ144M=";
    };

    # buildInputs = with prev; [
    #   (pythonPackages.specificPackage.override {
    #     version = "desired-version"; # Example dependency pinning
    #     # Additional attributes to modify, if needed
    #   })
    #   otherDependency # Any other dependencies, either pinned or untouched
    # ];
    #
    # propagatedBuildInputs = with prev; [
    #   (pythonPackages.anotherPackage.override {
    #     version = "another-version";
    #   })
    # ];
  };
}
