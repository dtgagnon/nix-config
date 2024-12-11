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

  sha256 = {
      x86_64-linux = "81f7fa8c2289f0beccf5b887539db9301eaa1c7693912df127e9b506d368cda0";
    }
    .${system} or throwSystem;

in
# https://windsurf-stable.codeium.com/api/update/linux-x64/stable/latest
callPackage "${inputs.nixpkgs}/pkgs/applications/editors/vscode/generic.nix" rec {
  inherit commandLineArgs useVSCodeRipgrep;

  version = "1.0.7";
  pname = "windsurf";

  executableName = "windsurf";
  longName = "Windsurf";
  shortName = "windsurf";

  src = fetchurl {
    url = "https://windsurf-stable.codeiumdata.com/${plat}/stable/bf4345439764c543a1e5ff3517bbce5a22128bca/Windsurf-${plat}-${version}.${archive_fmt}";
    inherit sha256;
  };

  sourceRoot = "Windsurf";

  tests = nixosTests.vscodium;

  updateScript = "nil";

  meta = {
    description = "Windsurf - A vsCodium fork + AI features";
    platforms = [ "x86_64-linux" ];
  };
}
