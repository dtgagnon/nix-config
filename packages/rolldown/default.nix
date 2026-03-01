{
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_10,
  nodejs_22,
  rustPlatform,
  cargo,
  rustc,
  cmake,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "rolldown";
  version = "1.0.0-rc.5";

  src = fetchFromGitHub {
    owner = "rolldown";
    repo = "rolldown";
    rev = "v${finalAttrs.version}";
    hash = "sha256-uqgJN7jn70z3cQlEEyk+0TeiHDn1AkvMmCaEOksHxhM=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    pname = "rolldown";
    version = finalAttrs.version;
    src = finalAttrs.src;
    hash = "sha256-tyayOAwdqP1euzicJrstwHiHxoFRWq+IGSiN/uFNZz8=";
  };

  pnpmDeps = fetchPnpmDeps {
    pname = "rolldown";
    version = finalAttrs.version;
    src = finalAttrs.src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    hash = "sha256-16NBCf4dP8a8dbgnmtFawMHKD7geIkLXt4F4w18FSUM=";
  };

  dontUseCmakeConfigure = true;

  nativeBuildInputs = [
    pnpmConfigHook
    pnpm_10
    nodejs_22
    rustPlatform.cargoSetupHook
    cargo
    rustc
    cmake
  ];

  buildPhase = ''
    runHook preBuild

    pnpm run --filter "@rolldown/pluginutils" build
    pnpm run --filter rolldown build-native:release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    local -r nodeModules="$out/lib/node_modules"
    mkdir -p "$nodeModules"

    local -r outPath="$nodeModules/rolldown"
    mkdir -p "$outPath"
    cp packages/rolldown/package.json "$outPath/"
    for d in bin cli dist; do
      [[ -d packages/rolldown/$d ]] && cp -r "packages/rolldown/$d" "$outPath/"
    done
    cp packages/rolldown/*.node "$outPath/" 2>/dev/null || true
    cp packages/rolldown/dist/*.node "$outPath/dist/" 2>/dev/null || true
    cp packages/rolldown/src/rolldown-binding.*.node "$outPath/dist/" 2>/dev/null || true

    mkdir -p "$nodeModules/@rolldown/pluginutils"
    cp packages/pluginutils/package.json "$nodeModules/@rolldown/pluginutils/"
    [[ -d packages/pluginutils/dist ]] && cp -r packages/pluginutils/dist "$nodeModules/@rolldown/pluginutils/"

    runHook postInstall
  '';

  meta = {
    description = "Fast Rust-based bundler for JavaScript";
    inherit (nodejs_22.meta) platforms;
  };
})
