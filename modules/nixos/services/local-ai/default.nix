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
    mkMerge
    types
    ;
  cfg = config.${namespace}.services.local-ai;
in
{
  options.${namespace}.services.local-ai = {
    enable = mkEnableOption "LocalAI - local OpenAI-compatible API server via OCI container";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to expose the LocalAI API on the host";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/local-ai";
      description = "Directory for persistent model storage and configuration";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest-gpu-nvidia-cuda-12";
      description = ''
        LocalAI container image tag. Common options:
        - latest (CPU only)
        - latest-gpu-nvidia-cuda-12 (NVIDIA CUDA 12)
        - latest-gpu-nvidia-cuda-13 (NVIDIA CUDA 13)
        - latest-aio-gpu-nvidia-cuda-12 (with bundled models)
        - latest-gpu-hipblas (AMD ROCm)
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
      description = "Whether to open the firewall for the LocalAI API port";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables passed to the LocalAI container";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = "podman";
      containers.local-ai = {
        image = "localai/localai:${cfg.imageTag}";
        autoStart = true;

        ports = [
          "${toString cfg.port}:8080"
        ];

        volumes = [
          "${cfg.dataDir}/models:/models"
        ];

        environment = {
          MODELS_PATH = "/models";
        } // cfg.extraEnvironment;

        extraOptions =
          (lib.optionals cfg.gpu [
            "--device=nvidia.com/gpu=all"
            "--security-opt=label=disable"
          ]);
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
      "d '${cfg.dataDir}/models' 0755 root root - -"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    ${namespace}.system.preservation.extraSysDirs = [
      cfg.dataDir
    ];
  };
}
