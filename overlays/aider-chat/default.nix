_: _final: prev:
let
  version = "0.59.0";
in
{
  aider-chat = prev.aider-chat.overrideAttrs {
    inherit version;
    pythonRelaxDeps = false;

    src = prev.fetchFromGitHub {
      owner = "paul-gauthier";
      repo = "aider";
      rev = "refs/tags/v${version}";
      hash = "sha256-20LicYj1j5gGzhF+SxPUKu858nHZgwDF1JxXeHRtYe0=";
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
