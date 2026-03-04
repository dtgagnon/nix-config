{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.${namespace}.services.speaches;
in
{
  options.${namespace}.services.speaches = {
    enable = mkEnableOption "Speaches - OpenAI-compatible TTS/STT server via OCI container";

    port = mkOption {
      type = types.port;
      default = 5053;
      description = "Port to expose the Speaches API on the host";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/speaches";
      description = "Directory for persistent model cache";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest-cuda";
      description = ''
        Speaches container image tag. Options:
        - latest-cuda (NVIDIA GPU)
        - latest-cpu (CPU only)
      '';
    };

    gpu = mkOption {
      type = types.bool;
      default = true;
      description = "Enable NVIDIA GPU passthrough to the container via CDI";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the Speaches API port";
    };

    preloadModels = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "kokoro" "hexgrad/Kokoro-82M" ];
      description = "List of model IDs to download during application startup";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        LOG_LEVEL = "info";
        STT_MODEL_TTL = "600";
        TTS_MODEL_TTL = "600";
      };
      description = "Additional environment variables passed to the Speaches container";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = "podman";
      containers.speaches = {
        image = "ghcr.io/speaches-ai/speaches:${cfg.imageTag}";
        autoStart = true;

        ports = [
          "${toString cfg.port}:8000"
        ];

        volumes = [
          "${cfg.dataDir}/hf-cache:/home/ubuntu/.cache/huggingface/hub"
        ];

        environment = {
          UVICORN_HOST = "0.0.0.0";
        }
        // lib.optionalAttrs (cfg.preloadModels != [ ]) {
          PRELOAD_MODELS = builtins.toJSON cfg.preloadModels;
        }
        // cfg.extraEnvironment;

        extraOptions =
          lib.optionals cfg.gpu [
            "--device=nvidia.com/gpu=all"
            "--security-opt=label=disable"
          ];
      };
    };

    # Ensure podman runtime is available
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # NVIDIA container toolkit provides CDI for GPU passthrough
    hardware.nvidia-container-toolkit.enable = mkIf cfg.gpu true;

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0755 root root - -"
      "d '${cfg.dataDir}/hf-cache' 0755 root root - -"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    ${namespace}.system.preservation.extraSysDirs = [
      cfg.dataDir
    ];
  };
}
