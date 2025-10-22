{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.virtualisation.kvm;
  dGPU = config.${namespace}.hardware.gpu.dGPU;

  diagnosticsScript = pkgs.writeShellScript "vfio-boot-diagnostics" ''
    #!/bin/sh

    LOG_FILE="/var/log/vfio-boot-diagnostics.log"

    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"

    # Timestamp for this boot
    echo "========================================" >> "$LOG_FILE"
    echo "Boot Diagnostics - $(date)" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Check dGPU driver binding
    echo "=== dGPU Driver Binding ===" >> "$LOG_FILE"
    GPU_BUS="${dGPU.busId}"
    GPU_AUDIO_BUS="$(echo ${dGPU.busId} | sed 's/\.0$/.1/')"

    if [ -e "/sys/bus/pci/devices/$GPU_BUS/driver" ]; then
      GPU_DRIVER=$(basename $(readlink "/sys/bus/pci/devices/$GPU_BUS/driver"))
      echo "GPU ($GPU_BUS): $GPU_DRIVER" >> "$LOG_FILE"
    else
      echo "GPU ($GPU_BUS): NO DRIVER BOUND" >> "$LOG_FILE"
    fi

    if [ -e "/sys/bus/pci/devices/$GPU_AUDIO_BUS/driver" ]; then
      AUDIO_DRIVER=$(basename $(readlink "/sys/bus/pci/devices/$GPU_AUDIO_BUS/driver"))
      echo "GPU Audio ($GPU_AUDIO_BUS): $AUDIO_DRIVER" >> "$LOG_FILE"
    else
      echo "GPU Audio ($GPU_AUDIO_BUS): NO DRIVER BOUND" >> "$LOG_FILE"
    fi
    echo "" >> "$LOG_FILE"

    # List loaded modules related to GPU/VFIO
    echo "=== Loaded Modules ===" >> "$LOG_FILE"
    lsmod | grep -E "vfio|nvidia|nouveau" >> "$LOG_FILE" 2>&1 || echo "No vfio/nvidia/nouveau modules loaded" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Check kernel command line
    echo "=== Kernel Command Line ===" >> "$LOG_FILE"
    cat /proc/cmdline >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Extract VFIO/PCI binding messages from dmesg
    echo "=== dmesg: VFIO/PCI Binding Timeline ===" >> "$LOG_FILE"
    dmesg | grep -iE "vfio|${dGPU.busId}|10de:2684|pci.*01:00" >> "$LOG_FILE" 2>&1 || echo "No relevant dmesg entries found" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Extract nvidia/nouveau driver messages
    echo "=== dmesg: NVIDIA/Nouveau Driver Messages ===" >> "$LOG_FILE"
    dmesg | grep -iE "nvidia|nouveau" | head -50 >> "$LOG_FILE" 2>&1 || echo "No nvidia/nouveau messages in dmesg" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Show PCI device details
    echo "=== PCI Device Details ===" >> "$LOG_FILE"
    lspci -vnn -s "$GPU_BUS" >> "$LOG_FILE" 2>&1 || echo "Could not query PCI device" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Check modprobe configuration
    echo "=== Modprobe Config for vfio-pci ===" >> "$LOG_FILE"
    grep -h "vfio" /etc/modprobe.d/* 2>/dev/null >> "$LOG_FILE" || echo "No vfio modprobe config found" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    echo "========================================" >> "$LOG_FILE"
    echo "End of diagnostics for this boot" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
  '';
in
{
  options.${namespace}.virtualisation.kvm.diagnostics = {
    enable = mkEnableOption "Enable VFIO boot diagnostics logging";
  };

  config = mkIf (cfg.enable && cfg.diagnostics.enable) {
    systemd.services.vfio-boot-diagnostics = {
      description = "VFIO Boot Diagnostics - Log driver binding state";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" "systemd-udev-settle.service" ];
      before = [ "display-manager.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${diagnosticsScript}";
        RemainAfterExit = false;
      };

      path = with pkgs; [
        coreutils
        kmod
        pciutils
        gnugrep
        gnused
      ];
    };
  };
}
