{ lib
, pkgs
, stdenv
, ...
}:
let
  inherit (lib) fetchFromGitHub;

  version = "16.4";
in
stdenv.mkDerivation {
  name = "tuleap";
  src = fetchFromGitHub {
    owner = "Enalean";
    repo = "tuleap";
    rev = "${version}";
    sha256 = "";
  };

  buildInputs = with pkgs; [
    nodejs
    yarn
    php
    composer
    docker
    git
  ];

  buildPhase = ''
    yarn install
    yarn build
    composer install
    make
  '';

  installPhase = ''
    mkdir -p $out
    cp -r * $out
  '';

  meta = with pkgs.lib; {
    description = "Tuleap Open ALM";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
