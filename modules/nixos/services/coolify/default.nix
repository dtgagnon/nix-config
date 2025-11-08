{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    types
    optionalString
    ;
  cfg = config.spirenix.services.coolify;

  # Generate default secrets if not provided
  secretsFile = "${cfg.dataDir}/.secrets";
in
{
  options.spirenix.services.coolify = {
    enable = mkEnableOption "Coolify self-hosted PaaS";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/coolify";
      description = "Directory to store Coolify data and configuration";
    };

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port for Coolify web interface";
    };

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "coolify.example.com";
      description = "Domain name for Coolify instance";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/coolify-env";
      description = ''
        Path to file containing environment variables for Coolify.
        Should contain APP_ID, APP_KEY, DB_PASSWORD, REDIS_PASSWORD, etc.
        Recommended to use with sops-nix for secret management.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open firewall ports for Coolify";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        AUTOUPDATE = "true";
      };
      description = "Additional environment variables for Coolify";
    };

    autoUpdate = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic updates of the Coolify container image";
    };
  };

  config = mkIf cfg.enable {
    # Sops secrets integration (uncomment and configure when ready)
    # sops.secrets.coolify-env = {
    #   sopsFile = ./secrets/coolify.yaml;
    #   format = "binary";
    #   owner = "root";
    #   group = "root";
    #   mode = "0400";
    # };
    #
    # Then set: spirenix.services.coolify.environmentFile = config.sops.secrets.coolify-env.path;
    #
    # Example secrets file format (coolify.yaml):
    # APP_ID=<random-32-chars>
    # APP_KEY=base64:<random-32-chars>
    # DB_PASSWORD=<random-32-chars>
    # REDIS_PASSWORD=<random-32-chars>
    # PUSHER_APP_ID=<random-32-chars>
    # PUSHER_APP_KEY=<random-32-chars>
    # PUSHER_APP_SECRET=<random-32-chars>

    # Enable Docker via oci-containers
    virtualisation.oci-containers = {
      backend = "docker";
      containers.coolify = {
        image = "ghcr.io/coollabsio/coolify:latest";
        autoStart = true;

        # Use host network mode (Coolify needs this for managing containers)
        extraOptions = [
          "--network=host"
          "--pull=always"
        ];

        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "${cfg.dataDir}/source:/data/coolify/source"
          "${cfg.dataDir}/ssh:/data/coolify/ssh"
          "${cfg.dataDir}/applications:/data/coolify/applications"
          "${cfg.dataDir}/databases:/data/coolify/databases"
          "${cfg.dataDir}/backups:/data/coolify/backups"
          "${cfg.dataDir}/services:/data/coolify/services"
          "${cfg.dataDir}/proxy:/data/coolify/proxy"
        ];

        environment = mkMerge [
          {
            APP_PORT = toString cfg.port;
            SSL_MODE = "off";
            APP_URL =
              if cfg.domain != null then "https://${cfg.domain}" else "http://localhost:${toString cfg.port}";
          }
          cfg.extraEnvironment
        ];

        # Use custom environmentFile if provided, otherwise use auto-generated secrets
        environmentFiles = if cfg.environmentFile != null then [ cfg.environmentFile ] else [ secretsFile ];
      };
    };

    # Enable Docker
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    # Create data directories
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 root root - -"
      "d '${cfg.dataDir}/source' 0750 root root - -"
      "d '${cfg.dataDir}/ssh' 0750 root root - -"
      "d '${cfg.dataDir}/applications' 0750 root root - -"
      "d '${cfg.dataDir}/databases' 0750 root root - -"
      "d '${cfg.dataDir}/backups' 0750 root root - -"
      "d '${cfg.dataDir}/services' 0750 root root - -"
      "d '${cfg.dataDir}/proxy' 0750 root root - -"
    ];

    # Generate secrets file if environmentFile is not provided
    systemd.services.coolify-secrets = mkIf (cfg.environmentFile == null) {
      description = "Generate Coolify secrets";
      wantedBy = [ "docker-coolify.service" ];
      before = [ "docker-coolify.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        if [ ! -f ${secretsFile} ]; then
          echo "Generating Coolify secrets..."
          cat > ${secretsFile} << EOF
        APP_ID=$(${pkgs.coreutils}/bin/head /dev/urandom | ${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 | ${pkgs.coreutils}/bin/head -c 32)
        APP_KEY=base64:$(${pkgs.coreutils}/bin/head /dev/urandom | ${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 | ${pkgs.coreutils}/bin/head -c 32)
        DB_PASSWORD=$(${pkgs.coreutils}/bin/head /dev/urandom | ${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 | ${pkgs.coreutils}/bin/head -c 32)
        REDIS_PASSWORD=$(${pkgs.coreutils}/bin/head /dev/urandom | ${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 | ${pkgs.coreutils}/bin/head -c 32)
        PUSHER_APP_ID=$(${pkgs.coreutils}/bin/head /dev/urandom | ${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 | ${pkgs.coreutils}/bin/head -c 32)
        PUSHER_APP_KEY=$(${pkgs.coreutils}/bin/head /dev/urandom | ${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 | ${pkgs.coreutils}/bin/head -c 32)
        PUSHER_APP_SECRET=$(${pkgs.coreutils}/bin/head /dev/urandom | ${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 | ${pkgs.coreutils}/bin/head -c 32)
        EOF
          chmod 600 ${secretsFile}
          echo "Secrets generated at ${secretsFile}"
        else
          echo "Secrets file already exists at ${secretsFile}"
        fi
      '';
    };

    # Open firewall if requested
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.port
        6001 # Soketi/Pusher port
      ];
    };
  };
}
