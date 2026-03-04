{
  lib,
  pkgs,
  config,
  namespace,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.${namespace}.services.comfyui;

  comfyuiSrc = inputs.comfyui-nix;

  # Upstream template-inputs.nix has a broken fetchurl (frog_depth_input.mp4 returns 404).
  # Intercept pkgs.fetchurl to skip that URL, then rebuild the package from source.
  brokenUrls = [
    "https://raw.githubusercontent.com/Comfy-Org/workflow_templates/refs/heads/main/input/frog_depth_input.mp4"
  ];
  patchedPkgs = pkgs // {
    fetchurl =
      args:
      if builtins.elem (args.url or "") brokenUrls then
        builtins.toFile "placeholder" ""
      else
        pkgs.fetchurl args;
  };

  versions = import "${comfyuiSrc}/nix/versions.nix";
  pythonOverrides = import "${comfyuiSrc}/nix/python-overrides.nix" {
    inherit pkgs versions;
    gpuSupport = "cuda";
  };
  comfyuiPackages = import "${comfyuiSrc}/nix/packages.nix" {
    pkgs = patchedPkgs;
    inherit (pkgs) lib;
    inherit versions pythonOverrides;
    gpuSupport = "cuda";
  };
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
      package = comfyuiPackages.default;
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
