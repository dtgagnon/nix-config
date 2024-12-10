{
  stdenv,
  inputs,
  callPackage,
  fetchurl,
  nixosTests,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isLinux,
  ...
}:
let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  plat =
    {
      x86_64-linux = "linux-x64";
      # Pretty sure these below aren't currently supported.
      # x86_64-darwin = "macos-x64";
      # aarch64-linux = "linux-arm64";
      # aarch64-darwin = "macos-arm64";
      # armv7l-linux = "linux-armhf";
    }
    .${system} or throwSystem;

  archive_fmt = if stdenv.hostPlatform.isDarwin then "zip" else "tar.gz";

  sha256 =
    {
      x86_64-linux = "f8ff6f491f0ba80b43ab48aa92aa53b8e57c8c58e5b531ca0c89732ae3722b86";
    }
    .${system} or throwSystem;

in
# https://windsurf-stable.codeium.com/api/update/linux-x64/stable/latest
callPackage "${inputs.nixpkgs}/pkgs/applications/editors/vscode/generic.nix" rec {
  inherit commandLineArgs useVSCodeRipgrep;

  version = "1.0.5";
  pname = "windsurf";

  executableName = "windsurf";
  longName = "Windsurf";
  shortName = "windsurf";

  src = fetchurl {
    url = "https://windsurf-stable.codeiumdata.com/${plat}/stable/d33d40f6cd3a4d7e451b22e94359230a4aa8c161/Windsurf-${plat}-${version}.${archive_fmt}";
    inherit sha256;
    # hash = "sha256-+P9vSR8LqAtDq0iqkqpTuOV8jFjltTHKDIlzKuNyK4Y=";
  };

  sourceRoot = "Windsurf";

  tests = nixosTests.vscodium;

  updateScript = "nil";

  meta = {
    description = "Windsurf - A vsCodium fork + AI features";
    platforms = [ "x86_64-linux" ];
  };
}
