{ lib
, stdenv
, inputs
, callPackage
, fetchurl
, nixosTests
, commandLineArgs ? ""
, useVSCodeRipgrep ? stdenv.hostPlatform.isLinux
, ...
}:
# https://windsurf-stable.codeium.com/api/update/linux-x64/stable/latest
callPackage "${inputs.nixpkgs}/pkgs/applications/editors/vscode/generic.nix" rec {
  inherit commandLineArgs useVSCodeRipgrep;

  version = "1.0.5";
  pname = "windsurf";

  executableName = "windsurf";
  longName = "Windsurf";
  shortName = "windsurf";

  src = fetchurl {
    url = "https://windsurf-stable.codeiumdata.com/linux-x64/stable/d33d40f6cd3a4d7e451b22e94359230a4aa8c161/Windsurf-linux-x64-1.0.5.tar.gz";
    hash = "sha256-+P9vSR8LqAtDq0iqkqpTuOV8jFjltTHKDIlzKuNyK4Y=";
  };

  sourceRoot = "Windsurf";

  tests = nixosTests.vscodium;

  updateScript = "nil";

  meta = {
    description = "The first agentic IDE, and then some";
  };
}
