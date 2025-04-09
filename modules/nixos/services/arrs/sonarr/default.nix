{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types mkMerge optionalAttrs toUpper concatStringsSep listToAttrs mapAttrsRecursive pipe collect isBool boolToString;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.arrs.sonarr;

  # Helper to create the 'settings' submodule option
  mkServarrSettingsOptions = name: defaultPort:
    mkOpt
      (types.submodule {
        freeformType = (pkgs.formats.ini { }).type; # Allow arbitrary INI-like structure
        options = {
          # Define common/important options explicitly for discoverability and defaults
          update = {
            mechanism = mkOpt (types.nullOr (types.enum [ "external" "builtIn" "script" ])) "which update mechanism to use" "external";
            automatically = mkBoolOpt false "Automatically download and install updates.";
          };
          server = {
            port = mkOpt types.int "Port Number" defaultPort;
          };
          log = {
            analyticsEnabled = mkBoolOpt false "Send Anonymous Usage Data";
            # You could add level here if desired:
            # level = mkOpt (types.enum ["Trace" "Debug" "Info" "Warn" "Error" "Fatal"]) "Logging level" "Info";
          };
          # Add other common sections/keys as needed
        };
      })
      { } # Default value for the whole submodule is empty attrset
      ''
        Attribute set of arbitrary config options for ${name}.
        These are converted to environment variables like `${builtins.toUpper name}__SECTION__KEY=value`.
        Consult the [Servarr Wiki](https://wiki.servarr.com/useful-tools#using-environment-variables-for-config) for available options.

        WARNING: this configuration is stored in the world-readable Nix store!
        For secrets use the `environmentFiles` option.
      '';

  # Helper to create the 'environmentFiles' option
  mkServarrEnvironmentFiles = name:
    mkOpt (types.listOf types.path) [ ]
      ''
        List of environment files to pass secret configuration values for ${name}.
        Each line must follow the `${builtins.toUpper name}__SECTION__KEY=value` pattern.
        Consult the [Servarr Wiki](https://wiki.servarr.com/useful-tools#using-environment-variables-for-config).
      '';

  # Helper to convert the 'settings' attrset into environment variables for systemd
  mkServarrSettingsEnvVars = name: settings:
    pipe settings [
      (mapAttrsRecursive (
        path: value:
          # Only create env var if value is not null
          optionalAttrs (value != null) {
            # Format: APPNAME__SECTION__KEY=value
            name = toUpper "${name}__${concatStringsSep "__" path}";
            # Convert value to string, handling booleans correctly
            value = toString (if isBool value then boolToString value else value);
          }
      ))
      # Collect only the valid { name = "VAR"; value = "val"; } attributes
      (collect (x: lib.isAttrs x && lib.isString x.name && lib.isString x.value))
      # Convert list of attrs to a single attrset { VAR = "val"; }
      listToAttrs
    ];
in
{
  options.${namespace}.services.arrs.sonarr = {
    enable = mkBoolOpt false "Enable Sonarr";
    package = mkOpt types.package pkgs.sonarr "The specific package to default to for the sonarr service";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Sonarr.";
    dataDir = mkOpt types.str "${config.spirenix.services.arrs.dataDir}/sonarr" "Directory for Sonarr data";
    enableAnimeServer = mkBoolOpt false "Enable a separate Sonarr instance for handling anime";
    animeSettings = mkServarrSettingsOptions "sonarr-anime" 8990;
    animeEnvironmentFiles = mkServarrEnvironmentFiles "sonarr-anime";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.sonarr = {
        enable = true;
        user = "sonarr";
        group = "media";
        inherit (cfg)
          package
          openFirewall
          dataDir
          ;
      };
    })
    (mkIf cfg.enableAnimeServer {
      systemd = {
        tmpfiles.rules = [ "d '${cfg.dataDir}-anime' 0700 sonarr media - -" ];
        services.sonarr-anime = {
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = mkServarrSettingsEnvVars "SONARR" cfg.animeSettings;
          serviceConfig = {
            Type = "simple";
            User = "sonarr";
            Group = "media";
            EnvironmentFile = cfg.animeEnvironmentFiles;
            ExecStart = "${cfg.package}/bin/Sonarr -nobrowser -data='${cfg.dataDir}-anime'";
            Restart = "on-failure";
          };
        };
      };
      networking.firewall = mkIf cfg.openFirewall {
        allowedTCPPorts = [ cfg.animeSettings.server.port ];
      };
    })
  ];
}
