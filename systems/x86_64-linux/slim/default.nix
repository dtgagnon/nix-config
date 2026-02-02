{ lib
, namespace
, pkgs
, inputs
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [
    ./disk-config.nix
    ./hardware.nix
  ];

  # ============================================================================
  # Boot Configuration
  # ============================================================================

  fileSystems."/boot".options = [ "umask=0077" ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = lib.mkDefault 3;
        consoleMode = lib.mkDefault "max";
        editor = false;
      };
    };

    initrd = {
      systemd.enable = true;
      systemd.emergencyAccess = true;
      luks.forceLuksSupportInInitrd = true;
      availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_usb_sdmmc" ];
      kernelModules = [ "dm-snapshot" ];
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = "slim";

    firewall = {
      enable = true;
      # SSH only - public access via Tailscale Funnel (no ports 80/443 needed!)
      allowedTCPPorts = [ 22 22022 ];
      # Tailscale interface is fully trusted
      trustedInterfaces = [ "tailscale0" ];
      # Hardening: Drop forwarding by default
      extraCommands = ''
        iptables -P FORWARD DROP
        ip6tables -P FORWARD DROP
      '';
    };
  };

  # ============================================================================
  # Spirenix Module Configuration
  # ============================================================================

  spirenix = {
    # Suites
    suites = {
      headless = enabled;
      networking = enabled;
    };

    # Hardware (server mode - desktop removed)
    hardware = {
      keyboard = enabled; # Console keyboard layout (needed for physical access/recovery)
      laptop = enabled; # Battery, lid, power management
    };

    # Security
    security = {
      pam = enabled;
      sudo = enabled;
      sops-nix = enabled;
    };

    # System
    system.enable = true;
    system.preservation = enabled;

    # Tools
    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };
  };

  # ============================================================================
  # Automated Maintenance
  # ============================================================================

  # Auto-rebuild when GitHub repo updates (replaces autoUpgrade)
  systemd.services.flake-auto-rebuild = {
    description = "Auto-rebuild when GitHub repo updates";
    path = with pkgs; [ git nixos-rebuild nix openssh sudo ];
    script = ''
      cd /persist/home/dtgagnon/nix-config
      git fetch origin main
      LOCAL=$(git rev-parse HEAD)
      REMOTE=$(git rev-parse origin/main)
      if [ "$LOCAL" != "$REMOTE" ]; then
        echo "Updates found: $LOCAL -> $REMOTE"
        git pull --ff-only origin main
        sudo nixos-rebuild switch --flake .#slim
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "dtgagnon";
    };
  };

  systemd.timers.flake-auto-rebuild = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/15"; # Every 15 minutes
      Persistent = true;
    };
  };

  # Automatic garbage collection (critical for 128GB disk)
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # Nix store optimization
  nix.optimise = {
    automatic = true;
    dates = [ "03:30" ];
  };

  # ============================================================================
  # System Version
  # ============================================================================

  system.stateVersion = "24.11";
}
