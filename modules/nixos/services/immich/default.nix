{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.services.immich;
in
{
  options.services.immich = {
    enable = mkBoolOpt false "Enable the Immich media server";
    port = mkOpt types.port 2283 "Port on which Immich will listen";
    mediaLocation = mkOpt types.path "/var/lib/immich" "Directory where Immich stores its data";
    secretsFile = mkOpt (types.nullOr types.path) null "Environment file containing secrets for Immich";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Immich";
    uploadLimit = mkOpt types.str "50mb" "Maximum upload size for media files";
    machine-learning = mkBoolOpt true "Enable machine learning features";
  };

  config = mkIf cfg.enable {
    services.immich = {
      enable = true;
      # package = pkgs.immich;
      inherit (cfg) 
        mediaLocation
        port
        secretsFile
      ;

      user = "immich";
      group = "immich";
      host = "localhost";

      environment = {
        IMMICH_LOG_LEVEL = "info";
      };

      settings = {
        server = ""; #Domain for publicly shared links, including http(s)://
        newVersionCheck = false;
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
        enable = cfg.machine-learning;
        # environment = {
        #   MACHINE_LEARNING_MODEL_TTL = "600";
        # };
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