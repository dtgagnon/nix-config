{ lib
, config
, namespace
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.apollo;

  # Apollo package by overriding sunshine
  apollo = pkgs.sunshine.overrideAttrs (oldAttrs: rec {
    pname = "apollo";
    version = "0.4.6";

    src = pkgs.fetchFromGitHub {
      owner = "ClassicOldSong";
      repo = "Apollo";
      rev = "v${version}";
      hash = "sha256-bjQdGo7JttWnrp7Z7BeU20A7y4YqIURtIzC146mr7go=";
      fetchSubmodules = true;
    };

    # Clear nixpkgs patches - they're for upstream Sunshine
    patches = [ ];

    # Patch CMake to accept system boost instead of exact version
    postPatch = (oldAttrs.postPatch or "") + ''
      # Remove version requirement entirely and disable FetchContent fallback
      substituteInPlace cmake/dependencies/Boost_Sunshine.cmake \
        --replace-fail 'find_package(Boost CONFIG ''${BOOST_VERSION} EXACT COMPONENTS ''${BOOST_COMPONENTS})' \
                       'find_package(Boost REQUIRED COMPONENTS ''${BOOST_COMPONENTS})' \
        --replace-fail 'if(NOT Boost_FOUND)' \
                       'if(FALSE)  # Disabled FetchContent - using system boost'
    '';

    # Build Apollo's web UI with vendored package-lock.json
    ui = pkgs.buildNpmPackage {
      pname = "${pname}-ui";
      inherit version src;

      npmDepsHash = "sha256-vuPjiQ7hWNJX6fd4u9y8YjcB2U4Zt0vDclj0E7GbadQ=";

      postPatch = ''
        cp ${./package-lock.json} ./package-lock.json
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        cp -a . "$out"/
        runHook postInstall
      '';
    };

    # Use our UI build instead of upstream's
    preBuild = ''
      cp -r ${ui}/build ../
    '';
  });
in
{
  options.${namespace}.services.apollo = {
    enable = mkBoolOpt false "Enable Apollo (Sunshine fork) game streaming server";
  };

  config = mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      package = apollo;
      autoStart = true;
      capSysAdmin = true;
    };
  };
}
