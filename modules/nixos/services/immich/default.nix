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

    host = mkOpt types.str "0.0.0.0" "IPv4 address which Immich will bind to";
    port = mkOpt types.str "2283" "Port on which Immich will listen";
    openFirewall = mkBoolOpt false "Open ports in the firewall for Immich";

    mediaLocation = mkOpt types.path "/srv/immich" "Directory where Immich stores its data";
    secretsFile = mkOpt (types.nullOr types.path) null "Environment file containing secrets for Immich";

    ml = mkBoolOpt true "Enable machine learning features";
    redis = mkBoolOpt true "Enable Redis for caching";
  };

  config = mkIf cfg.enable {
    services.immich = {
      enable = true;
      inherit (cfg)
        host
        mediaLocation
        secretsFile
        ;

      user = "immich";
      group = "immich";

      # IMMICH_PORT = "2283";
      environment = {
        IMMICH_LOG_LEVEL = "log";
        IMMICH_PORT = "${cfg.port}";
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
        port = 6379; # Set to 0 to disable TCP
      };

      settings = {
        "backup" = {
          "database" = {
            "cronExpression" = "0 02 * * *";
            "enabled" = true;
            "keepLastAmount" = 14;
          };
        };
        "ffmpeg" = {
          "accel" = "disabled";
          "accelDecode" = false;
          "acceptedAudioCodecs" = [
            "aac"
            "mp3"
            "libopus"
            "pcm_s16le"
          ];
          "acceptedContainers" = [
            "mov"
            "ogg"
            "webm"
          ];
          "acceptedVideoCodecs" = [
            "h264"
          ];
          "bframes" = -1;
          "cqMode" = "auto";
          "crf" = 23;
          "gopSize" = 0;
          "maxBitrate" = "0";
          "preferredHwDevice" = "auto";
          "preset" = "ultrafast";
          "refs" = 0;
          "targetAudioCodec" = "aac";
          "targetResolution" = "720";
          "targetVideoCodec" = "h264";
          "temporalAQ" = false;
          "threads" = 0;
          "tonemap" = "hable";
          "transcode" = "required";
          "twoPass" = false;
        };
        "image" = {
          "colorspace" = "p3";
          "extractEmbedded" = false;
          "preview" = {
            "format" = "jpeg";
            "quality" = 80;
            "size" = 1440;
          };
          "thumbnail" = {
            "format" = "webp";
            "quality" = 80;
            "size" = 250;
          };
        };
        "job" = {
          "backgroundTask" = {
            "concurrency" = 5;
          };
          "faceDetection" = {
            "concurrency" = 2;
          };
          "library" = {
            "concurrency" = 5;
          };
          "metadataExtraction" = {
            "concurrency" = 5;
          };
          "migration" = {
            "concurrency" = 5;
          };
          "notifications" = {
            "concurrency" = 5;
          };
          "search" = {
            "concurrency" = 5;
          };
          "sidecar" = {
            "concurrency" = 5;
          };
          "smartSearch" = {
            "concurrency" = 2;
          };
          "thumbnailGeneration" = {
            "concurrency" = 3;
          };
          "videoConversion" = {
            "concurrency" = 1;
          };
        };
        "library" = {
          "scan" = {
            "cronExpression" = "0 0 * * *";
            "enabled" = true;
          };
          "watch" = {
            "enabled" = false;
          };
        };
        "logging" = {
          "enabled" = true;
          "level" = "log";
        };
        "machineLearning" = {
          "clip" = {
            "enabled" = true;
            "modelName" = "ViT-B-32__openai";
          };
          "duplicateDetection" = {
            "enabled" = true;
            "maxDistance" = 0.01;
          };
          "enabled" = true;
          "facialRecognition" = {
            "enabled" = true;
            "maxDistance" = 0.5;
            "minFaces" = 3;
            "minScore" = 0.7;
            "modelName" = "buffalo_l";
          };
          "urls" = [
            "http =//localhost:3003"
          ];
        };
        "map" = {
          "darkStyle" = "https://tiles.immich.cloud/v1/style/dark.json";
          "enabled" = true;
          "lightStyle" = "https://tiles.immich.cloud/v1/style/light.json";
        };
        "metadata" = {
          "faces" = {
            "import" = false;
          };
        };
        "newVersionCheck" = {
          "enabled" = false;
        };
        "notifications" = {
          "smtp" = {
            "enabled" = false;
            "from" = "";
            "replyTo" = "";
            "transport" = {
              "host" = "";
              "ignoreCert" = false;
              "password" = "";
              "port" = 587;
              "username" = "";
            };
          };
        };
        "oauth" = {
          "autoLaunch" = false;
          "autoRegister" = true;
          "buttonText" = "Login with OAuth";
          "clientId" = "";
          "clientSecret" = "";
          "defaultStorageQuota" = 0;
          "enabled" = false;
          "issuerUrl" = "";
          "mobileOverrideEnabled" = false;
          "mobileRedirectUri" = "";
          "profileSigningAlgorithm" = "none";
          "scope" = "openid email profile";
          "signingAlgorithm" = "RS256";
          "storageLabelClaim" = "preferred_username";
          "storageQuotaClaim" = "immich_quota";
        };
        "passwordLogin" = {
          "enabled" = true;
        };
        "reverseGeocoding" = {
          "enabled" = true;
        };
        "server" = {
          "externalDomain" = "";
          "loginPageMessage" = "";
          "publicUsers" = true;
        };
        "storageTemplate" = {
          "enabled" = true;
          "hashVerificationEnabled" = true;
          "template" = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
        };
        "templates" = {
          "email" = {
            "albumInviteTemplate" = "";
            "albumUpdateTemplate" = "";
            "welcomeTemplate" = "";
          };
        };
        "theme" = {
          "customCss" = "";
        };
        "trash" = {
          "days" = 14;
          "enabled" = true;
        };
        "user" = {
          "deleteDelay" = 7;
        };
      };
    };

    sops.secrets.immich = {
      owner = "immich";
      group = "immich";
      mode = "0600";
    };

    users.groups.immich = { };
  };
}
