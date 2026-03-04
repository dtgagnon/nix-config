{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.${namespace}.services.comfyui;
in
{
  options.${namespace}.services.comfyui = {
    enable = mkEnableOption "ComfyUI node-based image generation interface";
    port = mkOption {
      type = types.port;
      default = 8188;
      description = "Port for the ComfyUI web interface";
    };
    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind the ComfyUI server to";
    };
    enableManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable ComfyUI-Manager for installing custom nodes";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/comfyui";
      description = "Directory for ComfyUI models, outputs, and custom nodes";
    };
  };

  config = mkIf cfg.enable {
    services.comfyui = {
      enable = true;
      gpuSupport = "cuda";
      port = cfg.port;
      listenAddress = cfg.listenAddress;
      enableManager = cfg.enableManager;
      dataDir = cfg.dataDir;
    };

    ${namespace}.system.preservation.extraSysDirs = [
      cfg.dataDir
    ];
  };
}
