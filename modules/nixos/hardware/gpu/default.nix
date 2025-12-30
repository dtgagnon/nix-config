{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types mkDefault mkMerge;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.gpu;

  # Helper to convert canonical hex PCI address (0000:01:00.0) → PCI:D:B:F (PCI:0:1:0)
  canonToPrime = canon:
    let
      # Drop the optional 4-digit domain (0000:)
      noDomain = lib.removePrefix "0000:" canon;
      # Split into "bus:device.function"
      parts1 = lib.splitString "." noDomain; # [ "bus:dev" "func" ]
      funcStr = builtins.elemAt parts1 1;
      parts2 = lib.splitString ":" (builtins.elemAt parts1 0); # [ "busHex" "devHex" ]
      busHex = builtins.elemAt parts2 0;
      devHex = builtins.elemAt parts2 1;

      # Simple hex→dec converter (lower-case input assumed)
      hexDigits = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "b" = 11;
        "c" = 12;
        "d" = 13;
        "e" = 14;
        "f" = 15;
      };
      hexToDec = hex:
        let
          chars = lib.stringToCharacters (lib.toLower hex);
        in
        builtins.foldl' (acc: ch: acc * 16 + hexDigits.${ch}) 0 chars;

      busDec = toString (hexToDec busHex);
      devDec = toString (hexToDec devHex);
    in
    "PCI:${busDec}:${devDec}:${funcStr}";
in
{
  options.${namespace}.hardware.gpu = {
    enable = mkBoolOpt true "Enable hardware configuration for basic nvidia gpu settings";
    iGPU = {
      isPrimary = mkBoolOpt false "Designate the iGPU as the primary renderer (false defaults to dGPU)";
      mfg = mkOpt (types.nullOr (types.enum [ "intel" "amd" ])) null "Choose the iGPU CPU manufacturer";
      deviceIds = mkOpt (types.listOf types.str) [ ] "The device IDs of the iGPU";
      busId = mkOpt (types.nullOr types.str) null "The bus ID of the iGPU";
    };
    dGPU = {
      mfg = mkOpt (types.nullOr (types.enum [ "nvidia" "intel" "amd" ])) null "Choose the dGPU manufacturer";
      deviceIds = mkOpt (types.listOf types.str) [ ] "The device IDs of the dGPU";
      busId = mkOpt (types.nullOr types.str) null "The bus ID of the dGPU";
    };
    nvidiaChannel = mkOpt (types.enum [ "stable" "beta" "latest" ]) "stable" "Declare the nvidia driver release channel (stable, latest (production), beta)";
    nvidiaPrime = mkBoolOpt false "Whether to use nvidia's PRIME dGPU offload/sync feature";
    nvidiaOpen = mkBoolOpt false "Use nvidia open-sourced kernel modules (on RTX series GPUs and newer)";
  };

  config = mkMerge [
    (mkIf (cfg.enable && cfg.dGPU.mfg == "nvidia") {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware = {
        nvidia = {
          nvidiaPersistenced = false;
          nvidiaSettings = true;
          open = cfg.nvidiaOpen; #TODO: Test if `lib.mkOverride 990 (config.hardware.nvidia.package ? open && config.hardware.nvidia.package ? firmware)` works as intended
          #TODO: Remove this patch when nixpkgs NVIDIA driver includes the kernel 6.18+ get_dev_pagemap() API fix.
          # Patch addresses: https://github.com/NVIDIA/open-gpu-kernel-modules/commit/3e230516034d29e84ca023fe95e284af5cd5a065
          # Check if fixed in driver version >= 580.x or when nixpkgs updates stable/latest channels with the fix.
          package =
            # if cfg.nvidiaOpen then
            #   config.boot.kernelPackages.nvidiaPackages.${cfg.nvidiaChannel} // {
            #     open = config.boot.kernelPackages.nvidiaPackages.${cfg.nvidiaChannel}.open.overrideAttrs (old: {
            #       patches = (old.patches or [ ]) ++ [
            #         (pkgs.fetchpatch {
            #           name = "get_dev_pagemap.patch";
            #           url = "https://github.com/NVIDIA/open-gpu-kernel-modules/commit/3e230516034d29e84ca023fe95e284af5cd5a065.patch";
            #           hash = "sha256-BhL4mtuY5W+eLofwhHVnZnVf0msDj7XBxskZi8e6/k8=";
            #         })
            #       ];
            #     });
            #   }
            # else
              config.boot.kernelPackages.nvidiaPackages.${cfg.nvidiaChannel};
          modesetting.enable = true;
          powerManagement = {
            enable = true;
            finegrained = false;
          };
          prime = mkIf cfg.nvidiaPrime {
            offload = { enable = true; enableOffloadCmd = true; };
            intelBusId = canonToPrime cfg.iGPU.busId;
            nvidiaBusId = canonToPrime cfg.dGPU.busId;
          };
          videoAcceleration = true; # True adds the pkgs.nvidia-vaapi-driver.
        };
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            libvdpau-va-gl
          ];
        };
      };

      systemd.services = {
        nvidia-suspend.enable = true;
        nvidia-resume.enable = true;
      };

      environment.systemPackages = with pkgs; [
        nvtopPackages.full
        vulkan-tools
      ];

      #TODO: I think this can move into the kvm module; not sure why I put it here
      boot = {
        blacklistedKernelModules = [ "nouveau" "nvidiafb" ];
      };
    })

    (mkIf (cfg.enable && cfg.iGPU.mfg == "intel") {
      services.xserver.videoDrivers = [ "modesetting" ];
      hardware.graphics = {
        enable = mkDefault true;
        enable32Bit = mkDefault true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-vaapi-driver
          vpl-gpu-rt
          libva-vdpau-driver
          libvdpau-va-gl
        ];
      };
      boot = {
        kernelModules = [ "i915" ];
        kernelParams = [
          "i915.force_probe=a780"
          "i915.enable_fbc=1"
          "i915.enable_psr=2"
          "i915.modeset=1"
        ] ++ lib.optional cfg.iGPU.isPrimary (lib.mkForce "nvidia-drm.fbdev=0");
      };
      environment.variables = {
        LIBVA_DRIVER_NAME = mkIf cfg.iGPU.isPrimary "iHD";
        VDPAU_DRIVER = "va_gl";
        MOZ_DISABLE_RDD_SANDBOX = "1";
      };
    })
  ];
}
