{ lib, ... }: final: prev:
let
  inherit (final) fetchFromGitHub rustPlatform stdenv;
  python3Packages = final.python3Packages;
in
{
  aw-watcher-input = python3Packages.buildPythonApplication rec {
    pname = "aw-watcher-input";
    version = "0.1.0-unstable-2024-10-17";

    pyproject = true;
    build-system = [ python3Packages.poetry-core ];

    src = fetchFromGitHub {
      owner = "ActivityWatch";
      repo = "aw-watcher-input";
      rev = "9bb5045456524b215ae11f422b80ec728c93bac7";
      hash = "sha256-T7RIzrv+WzA5gEUlU/0dR1Fl0b8zH8q/q80WMBIosPM=";
    };

    dependencies =
      with python3Packages;
      [
        aw-client
        aw-core
        click
        typing-extensions
      ]
      ++ [ final.aw-watcher-afk ];

    pythonRelaxDeps = [
      "aw-client"
      "aw-watcher-afk"
    ];

    pythonImportsCheck = [ "aw_watcher_input" ];

    meta = with lib; {
      description = "Keyboard and mouse input watcher for ActivityWatch";
      homepage = "https://github.com/ActivityWatch/aw-watcher-input";
      license = licenses.mpl20;
      maintainers = with maintainers; [ dtgagnon ];
      mainProgram = "aw-watcher-input";
      platforms = platforms.unix;
    };
  };

  aw-watcher-media-player = rustPlatform.buildRustPackage rec {
    pname = "aw-watcher-media-player";
    version = "1.1.1"; # from Cargo.toml

    src = fetchFromGitHub {
      owner = "2e3s";
      repo = "aw-watcher-media-player";
      rev = "d170c56bcc82ca62cbd2efeffc7202c3b86c3d90";
      hash = "sha256-htA5RanTIi/XVqrwMoxvuwFO7/QyztAZ29qqeqGGIvY=";
    };

    cargoHash = lib.fakeHash;

    nativeBuildInputs = [ final.pkg-config ];

    buildInputs = lib.optionals stdenv.isLinux [
      final.dbus
    ];

    postInstall = ''
      install -Dm644 visualization/index.html \
        "$out/share/${pname}/visualization/index.html"
    '';

    meta = with lib; {
      description = "Report currently playing media to ActivityWatch";
      homepage = "https://github.com/2e3s/aw-watcher-media-player";
      license = licenses.mpl20;
      maintainers = with maintainers; [ dtgagnon ];
      mainProgram = "aw-watcher-media-player";
      platforms = platforms.unix;
    };
  };
}
