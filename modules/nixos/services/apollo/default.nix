{ lib
, config
, namespace
, pkgs
, ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    types
    optionalAttrs
    ;
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

  defaultPort = 47989;
  appsFormat = pkgs.formats.json { };
  settingsFormat = pkgs.formats.keyValue { };

  appsFile = appsFormat.generate "apollo-apps.json" cfg.applications;
in
{
  options.${namespace}.services.apollo = {
    enable = mkBoolOpt false "Enable Apollo (Sunshine fork) game streaming server";

    package = mkOption {
      type = types.package;
      default = apollo;
      description = "Package to run for Apollo (Sunshine fork).";
    };

    openFirewall = mkBoolOpt false "Automatically open required streaming ports.";

    capSysAdmin = mkBoolOpt false "Grant CAP_SYS_ADMIN via wrapper for DRM/KMS capture.";

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically start Apollo in the user session.";
    };

    settings = mkOption {
      default = { };
      description = ''
        Key/value settings rendered to apollo.conf. Matches upstream Sunshine config.
        When set (or when applications are provided), Apollo runs fully declaratively.
      '';
      type = types.submodule (settings: {
        freeformType = settingsFormat.type;
        options.port = mkOption {
          type = types.port;
          default = defaultPort;
          description = "Base port; other Sunshine ports are offsets from this.";
        };
      });
    };

    applications = mkOption {
      default = { };
      description = ''
        Applications exposed to Moonlight, rendered to apps.json. Same schema as the
        upstream module (env + apps list). If set, web UI app config is disabled.
      '';
      type = types.submodule {
        options = {
          env = mkOption {
            default = { };
            type = types.attrsOf types.str;
            description = "Environment variables applied to launched apps.";
          };
          apps = mkOption {
            default = [ ];
            type = types.listOf types.attrs;
            description = "List of application definitions (passed through as-is).";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Delegate to the upstream Sunshine module, but point it at the Apollo build
    services.sunshine = {
      enable = true;
      package = cfg.package;
      inherit (cfg) openFirewall capSysAdmin autoStart applications;
      # Wire apps.json path when provided
      settings = cfg.settings // optionalAttrs (cfg.applications.apps != [ ]) { file_apps = appsFile; };
    };

    # Provide a user service alias so it can be managed as apollo.service
    systemd.user.services.sunshine.aliases = [ "apollo.service" ];
  };
}
