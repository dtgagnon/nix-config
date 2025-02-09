{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.immich;
in
{
  options.${namespace}.services.immich = {
    enable = mkBoolOpt false "Enable the Immich media server";
    port = mkOpt types.port 2283 "Port on which Immich will listen";
    mediaLocation = mkOpt types.path "/var/lib/immich" "Directory where Immich stores its data";
    secretsFile = mkOpt (types.nullOr types.path) null "Environment file containing secrets for Immich";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Immich";
    uploadLimit = mkOpt types.str "50mb" "Maximum upload size for media files";
    ml = mkBoolOpt true "Enable machine learning features";
    redis = mkBoolOpt true "Enable Redis for caching";
  };

  config = mkIf cfg.enable {
    services.immich = {
      enable = true;
      inherit (cfg)
        mediaLocation
        port
        secretsFile
        ;

      user = "immich";
      group = "immich";
      host = "localhost";

      environment = {
        IMMICH_LOG_LEVEL = "log";
        IMMICH_HOST = "0.0.0.0";
        IMMICH_PORT = "2283";
      };

      settings = {
        server.externalDomain = ""; #Domain for publicly shared links, including http(s)://
        newVersionCheck.enabled = false;
      };

      database = {
        enable = true; # enable the postgresql database
        createDB = true; # enable automatic database creation
        host = "/run/postgresql";
        port = 5432;
        name = "immich";
        user = "immich";
      };

      machine-learning = {
        enable = cfg.ml;
        environment = {
          MACHINE_LEARNING_MODEL_TTL = "600";
        };
      };

      redis = {
        enable = cfg.redis;
        host = "localhost";
        port = 0; # Set to 0 to disable TCP
      };
    };

    sops.secrets.immich = {
      owner = "immich";
      group = "immich";
      mode = "0600";
    };
  };
}
