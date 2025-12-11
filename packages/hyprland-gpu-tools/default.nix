{ lib
, pkgs
, stdenv
, writeShellScriptBin
, symlinkJoin
, coreutils
}:

symlinkJoin {
  name = "hyprland-gpu-tools";
  paths = [
    # GPU detection and environment variable utility
    (writeShellScriptBin "hyprland-gpu-env" ''
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
          echo "export AQ_DRM_DEVICES=$DGPU_SYMLINK"
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
    '')

    # Hyprland session launcher - dGPU mode
    (writeShellScriptBin "hyprland-uwsm-dgpu" ''
      export HYPRLAND_GPU_MODE=dgpu
      exec uwsm start hyprland.desktop
    '')

    # Hyprland session launcher - iGPU mode
    (writeShellScriptBin "hyprland-uwsm-igpu" ''
      export HYPRLAND_GPU_MODE=igpu
      exec uwsm start hyprland.desktop
    '')
  ];

  meta = with lib; {
    description = "Hyprland GPU detection utility and session launchers";
    platforms = platforms.linux;
  };
}
