{
  lib,
  pkgs,
  stdenv,
  writeShellScriptBin,
  symlinkJoin,
  coreutils,
  inputs,
  system,
}:
let
  # GPU detection and environment variable utility
  gpuEnv = writeShellScriptBin "hyprland-gpu-env" ''
    #!${stdenv.shell}
    # hyprland-gpu-env - Detect available GPU and output Hyprland environment variables
    # Usage: hyprland-gpu-env [dgpu|igpu|auto]

    MODE="''${1:-auto}"
    STATE_FILE="/var/lib/systemd/vfio-dgpu-state"
    DGPU_BUS_ID="0000:01:00.0"
    IGPU_SYMLINK="$HOME/.config/hypr/intel-iGPU"
    DGPU_SYMLINK="$HOME/.config/hypr/nvidia-dGPU"

    # Function to check which driver is bound to dGPU
    get_dgpu_driver() {
        if [ -L "/sys/bus/pci/devices/$DGPU_BUS_ID/driver" ]; then
            ${coreutils}/bin/basename "$(${coreutils}/bin/readlink -f /sys/bus/pci/devices/$DGPU_BUS_ID/driver)"
        else
            echo "none"
        fi
    }

    # Function to output dGPU environment
    output_dgpu() {
        echo "# dGPU mode - using NVIDIA RTX 4090"
        echo "export AQ_DRM_DEVICES=$DGPU_SYMLINK:$IGPU_SYMLINK"
        echo "# Full graphics stack available (no EGL restriction)"
    }

    # Function to output iGPU environment
    output_igpu() {
        echo "# iGPU mode - using Intel iGPU"
        echo "export AQ_DRM_DEVICES=$IGPU_SYMLINK"
        echo "# Restrict EGL to Mesa to prevent NVIDIA fd leaks"
        echo "export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"
    }

    # GPU selection logic based on mode
    case "$MODE" in
        dgpu)
            # Force dGPU mode
            output_dgpu
            ;;
        igpu)
            # Force iGPU mode
            output_igpu
            ;;
        auto)
            # Automatic detection based on VFIO state and driver binding

            # Read VFIO state (default to 1/VFIO if file doesn't exist - safe default)
            VFIO_STATE=1
            if [ -f "$STATE_FILE" ]; then
                VFIO_STATE=$(${coreutils}/bin/cat "$STATE_FILE")
            fi

            # Verify actual driver binding
            DGPU_DRIVER=$(get_dgpu_driver)

            # Decision logic: Use dGPU only if state=0 AND driver=nvidia
            if [ "$VFIO_STATE" = "0" ] && [ "$DGPU_DRIVER" = "nvidia" ]; then
                echo "# Auto-detected: dGPU available (state=$VFIO_STATE, driver=$DGPU_DRIVER)"
                output_dgpu
            else
                echo "# Auto-detected: dGPU unavailable (state=$VFIO_STATE, driver=$DGPU_DRIVER)"
                output_igpu
            fi
            ;;
        *)
            echo "# ERROR: Invalid mode '$MODE'. Usage: hyprland-gpu-env [dgpu|igpu|auto]" >&2
            echo "# Falling back to iGPU (safe default)"
            output_igpu
            exit 1
            ;;
    esac
  '';

  # Hyprland GPU env setup - auto mode
  # Just writes the env file, used by desktop entries that call uwsm directly
  setupEnvAuto = writeShellScriptBin "hyprland-setup-env-auto" ''
    #!${stdenv.shell}
    mkdir -p "$HOME/.config/uwsm"
    ${lib.getExe gpuEnv} auto | grep "^export" > "$HOME/.config/uwsm/env-hyprland"
  '';

  # Hyprland GPU env setup - dGPU mode
  setupEnvDgpu = writeShellScriptBin "hyprland-setup-env-dgpu" ''
    #!${stdenv.shell}
    mkdir -p "$HOME/.config/uwsm"
    ${lib.getExe gpuEnv} dgpu | grep "^export" > "$HOME/.config/uwsm/env-hyprland"
  '';

  # Hyprland GPU env setup - iGPU mode
  setupEnvIgpu = writeShellScriptBin "hyprland-setup-env-igpu" ''
    #!${stdenv.shell}
    mkdir -p "$HOME/.config/uwsm"
    ${lib.getExe gpuEnv} igpu | grep "^export" > "$HOME/.config/uwsm/env-hyprland"
  '';

  # Hyprland session launcher - auto mode
  launcherAuto = writeShellScriptBin "hyprland-uwsm" ''
    #!${stdenv.shell}
    MODE=auto
    LOG_DIR="$HOME/.local/state/uwsm"
    mkdir -p "$LOG_DIR"
    exec >"$LOG_DIR/hyprland-uwsm-''${MODE}.log" 2>&1
    set -x
    ${lib.getExe setupEnvAuto}
    exec ${pkgs.uwsm}/bin/uwsm start hyprland.desktop
  '';

  # Hyprland session launcher - dGPU mode
  launcherDgpu = writeShellScriptBin "hyprland-uwsm-dgpu" ''
    #!${stdenv.shell}
    MODE=dgpu
    LOG_DIR="$HOME/.local/state/uwsm"
    mkdir -p "$LOG_DIR"
    exec >"$LOG_DIR/hyprland-uwsm-''${MODE}.log" 2>&1
    set -x
    ${lib.getExe setupEnvDgpu}
    exec ${pkgs.uwsm}/bin/uwsm start hyprland.desktop
  '';

  # Hyprland session launcher - iGPU mode
  launcherIgpu = writeShellScriptBin "hyprland-uwsm-igpu" ''
    #!${stdenv.shell}
    MODE=igpu
    LOG_DIR="$HOME/.local/state/uwsm"
    mkdir -p "$LOG_DIR"
    exec >"$LOG_DIR/hyprland-uwsm-''${MODE}.log" 2>&1
    set -x
    ${lib.getExe setupEnvIgpu}
    exec ${pkgs.uwsm}/bin/uwsm start hyprland.desktop
  '';

  # Hyprland runner that captures verbose logs for debugging
  hyprlandRunner = writeShellScriptBin "hyprland-run" ''
    #!${stdenv.shell}
    LOG_DIR="$HOME/.local/state/uwsm"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/hyprland-run.log"

    # UWsm writes env-hyprland; source it explicitly to ensure AQ_DRM_DEVICES is active
    if [ -f "$HOME/.config/uwsm/env-hyprland" ]; then
      . "$HOME/.config/uwsm/env-hyprland"
    fi

    export HYPRLAND_LOG_WLR=1
    export HYPRLAND_DEBUG=1

    echo "== $(date -Iseconds) starting Hyprland as $USER ==" >>"$LOG_FILE"
    exec ${inputs.hyprland.packages.${system}.hyprland}/bin/Hyprland >>"$LOG_FILE" 2>&1
  '';
in
symlinkJoin {
  name = "hyprland-gpu-tools";
  paths = [
    gpuEnv
    setupEnvAuto
    setupEnvDgpu
    setupEnvIgpu
    launcherAuto
    launcherDgpu
    launcherIgpu
    hyprlandRunner
  ];

  meta = with lib; {
    description = "Hyprland GPU detection utility, env setup, and UWSM launchers";
    platforms = platforms.linux;
  };
}
