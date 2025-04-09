# ~/nixos-config/pkgs/tuleap/default.nix (or wherever you place it)
{ lib
, pkgs
, stdenv
, fetchurl
, makeWrapper # Needed for pnpm wrapper
, fetchFromGitHub
}:

let
  # Define the custom pnpm derivation based on Tuleap's pnpm.nix
  tuleap-pnpm = stdenv.mkDerivation (finalAttrs: {
    pname = "pnpm";
    version = "8.15.9";
    src = fetchurl {
      url = "https://registry.npmjs.org/pnpm/-/pnpm-${finalAttrs.version}.tgz";
      hash = "sha256-2qJ6C1QbxjUyP/lsLe2ZVGf/n+bWn/ZwIVWKqa2dzDY=";
    };
    buildInputs = [ pkgs.nodejs_20 ]; # Use the same Node version
    nativeBuildInputs = [ makeWrapper ];

    preConfigure = ''
      rm -rf dist/reflink.*node dist/vendor || true
    '';

    installPhase = ''
      runHook preInstall
      install -d $out/libexec/pnpm $out/bin
      cp -R . $out/libexec/pnpm
      ln -s $out/libexec/pnpm/bin/pnpm.cjs $out/bin/pnpm
      wrapProgram $out/bin/pnpm --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs_20 ]}
      runHook postInstall
    '';
    dontConfigure = true;
    dontBuild = true;
    meta = {
      description = "Fast, disk space efficient package manager (Tuleap specific version)";
      homepage = "https://pnpm.io/";
      license = lib.licenses.mit; # Please verify pnpm's license
    };
  });

  # Define the PHP environment based on php-base.nix and build-tools-php.nix
  phpForTuleap = pkgs.php82.withExtensions ({ enabled, all }: enabled ++ [
    # Using pkgs.php82
    all.ffi
    all.bcmath
    all.curl
    all.ctype
    all.dom
    all.fileinfo
    all.filter
    all.gd
    all.gettext
    all.iconv
    all.intl
    all.ldap
    all.mbstring
    all.mysqli
    all.mysqlnd
    all.opcache
    all.openssl
    all.pcntl
    all.pdo_mysql
    all.posix
    all.readline
    all.session
    all.simplexml
    all.sodium
    all.tokenizer
    all.xmlreader
    all.xmlwriter
    all.zip
    all.zlib
    all.mailparse
    all.imagick
    all.sysvsem
    all.redis
    all.xsl
  ]
    # Ensure necessary libraries for extensions are implicitly included by Nixpkgs PHP infra
    # Or add explicit pkgs here if build fails (e.g., pkgs.imagemagick)
  );

  composerForTuleap = phpForTuleap.packages.composer;

  #TODO: TASK 4: Choose a specific Tuleap version tag from GitHub.
  tuleapVersion = "16.6"; # Replace with the desired stable tag from Enalean/tuleap/tags

in
pkgs.php.buildComposerProject rec {
  pname = "tuleap-code";
  version = tuleapVersion;

  src = fetchFromGitHub {
    owner = "Enalean";
    repo = "tuleap";
    rev = "refs/tags/${version}";
    #TODO: TASK 5: Calculate the correct hash.
    # Run build with lib.fakeSha256, copy hash from error, replace here.
    hash = "sha256-5Oija93j1m8FHzheGIaC7WM/DF+7yCUzDAvjIyKx1XI=";
  };

  composerLock = "src/composer.lock";
  vendorHash = "";

  nativeBuildInputs = with pkgs; [
    # General Build Tools
    coreutils
    gnugrep
    gnused
    gnumake
    findutils
    gitMinimal
    gettext
    bash
    which
    cacert

    # Other Build Packages
    file
    diffutils
    perl
    # pkgs.rpm # Only needed if running Tuleap's RPM build scripts

    # PHP Build Tools
    phpForTuleap

    # JS Build Tools
    nodejs_20
    tuleap-pnpm

    # Libraries for PHP Extensions (Nixpkgs usually handles these when enabling exts)
    libxslt # For php's xsl extension
    # Add others like pkgs.imagemagick, pkgs.cyrus_sasl if needed
  ];

  # Configure environment for sandboxed builds
  preConfigure = ''
    export HOME=$(mktemp -d)
    export COMPOSER_CACHE_DIR="$TMPDIR/composer-cache"
    mkdir -p $COMPOSER_CACHE_DIR
    export XDG_CACHE_HOME="$TMPDIR/pnpm-cache"
    mkdir -p $XDG_CACHE_HOME/pnpm
    export DO_NOT_TRACK=1
    export STORYBOOK_DISABLE_TELEMETRY=1
  '';

  # Might need to adjust build commands based on Makefile or package.json inspection
  buildPhase = ''
    runHook preBuild

    echo "Using PHP: $(which php)" && php --version
    echo "Using Composer: $(which composer)" && composer --version
    echo "Using Node: $(which node)" && node --version
    echo "Using pnpm: $(which pnpm)" && pnpm --version

    # Install PHP dependencies
    # Check Tuleap's composer.json for specific scripts if this fails
    composer install --working-dir=src --no-dev --optimize-autoloader --no-interaction --no-progress

    # Install Node.js dependencies and build frontend assets
    # Check Tuleap's package.json scripts section for actual build command name
    pnpm install --frozen-lockfile
    pnpm run build # Assuming 'build' is the correct script name in package.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Copy the necessary application code, vendor dirs, and built assets
    mkdir -p $out/share/tuleap
    cp -R --reflink=auto ./* $out/share/tuleap/

    # Exclude unnecessary files
    rm -rf $out/share/tuleap/.git
    rm -rf $out/share/tuleap/node_modules # Usually not needed at runtime
    # Consider other exclusions: tests/, docs/, .github/, etc.

    runHook postInstall
  '';

  # Pass useful components to the module later
  passthru = {
    inherit phpForTuleap composerForTuleap tuleap-pnpm;
    nodejs = pkgs.nodejs_20;
  };

  meta = with lib; {
    description = "Tuleap source code and pre-built assets";
    homepage = "https://www.tuleap.org/";
    license = licenses.gpl2Plus; # Verify license from LICENSE file
    maintainers = with maintainers; [ dtgagnon ];
    platforms = platforms.linux;
  };
}
