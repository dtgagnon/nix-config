{ fetchFromGitHub, ... }: final: prev:
let
  version = "0.23.0";
  gitRev = "v${version}";
  srcHash = "";
  pnpmDepsHash = "";
in
{
  hoarder = prev.hoarder.overrideAttrs (oldAttrs: {
    version = version;
    src = fetchFromGitHub prev.src // {
      tag = gitRev;
      hash = srcHash;
    };
    pnpmDeps = final.pnpm_9.fetchDeps prev.pnpmDeps // {
      inherit version;
      src = final.stdenv.mkDerivation prev.pnpmDeps.src // {
        src = final.hoarder.src;
      };
      hash = pnpmDepsHash;
    };
  });
}
