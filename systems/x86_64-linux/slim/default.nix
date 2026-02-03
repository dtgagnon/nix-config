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

  # OpenClaw runs in isolated VM - prompt injection risk accepted
  nixpkgs.config.permittedInsecurePackages = [ "openclaw-2026.1.30" ];

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
      availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_usb_sdmmc" ];
    };

    kernelModules = [ "kvm-intel" ];
  };

  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = "slim";

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [ "tailscale0" "microvm" ];
    };

    # Bridge for microVM networking
    nat = {
      enable = true;
      internalInterfaces = [ "microvm" ];
      externalInterface = "wlp2s0";
    };
  };

  # ============================================================================
  # Spirenix Module Configuration
  # ============================================================================

  spirenix = {
    suites = {
      headless = enabled;
      networking = enabled;
    };

    hardware = {
      keyboard = enabled;
      laptop = enabled;
    };

    security = {
      pam = enabled;
      sudo = enabled;
      sops-nix = enabled;
      vpn.enable = false;
    };

    system.enable = true;
    system.preservation = {
      enable = true;
      extraSysDirs = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/microvms"
      ];
    };

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
    };
  };

  # ============================================================================
  # MicroVM Host Configuration
  # ============================================================================

  microvm = {
    host.enable = true;
    autostart = [ "openclaw" ];

    vms.openclaw = {
      pkgs = pkgs;
      config = {
        microvm = {
          hypervisor = "cloud-hypervisor";
          vcpu = 4;
          mem = 3072; # 3GB for VM, leaves ~700MB for host

          # Use dedicated partition as VM's root volume
          volumes = [{
            image = "/var/lib/microvms/openclaw/root.img";
            mountPoint = "/";
            size = 15360; # 15GB
          }];

          interfaces = [{
            type = "tap";
            id = "vm-openclaw";
            mac = "02:00:00:00:00:01";
          }];

          # Share host's nix store read-only
          shares = [{
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            tag = "ro-store";
            proto = "virtiofs";
          }];
        };

        # Nix store overlay: ro-store from host + local writable layer
        fileSystems."/nix/store" = {
          overlay = {
            lowerdir = [ "/nix/.ro-store" ];
            upperdir = "/nix/.rw-store/upper";
            workdir = "/nix/.rw-store/work";
          };
        };

        # VM's internal NixOS configuration
        networking = {
          hostName = "openclaw";
          useNetworkd = true;
          useDHCP = false;
          interfaces.eth0 = {
            useDHCP = false;
            ipv4.addresses = [{
              address = "10.0.0.2";
              prefixLength = 24;
            }];
          };
          defaultGateway = {
            address = "10.0.0.1";
            interface = "eth0";
          };
          nameservers = [ "1.1.1.1" "8.8.8.8" ];
        };

        # Enable flakes for per-task environments
        nix.settings = {
          experimental-features = [ "nix-command" "flakes" ];
          trusted-users = [ "openclaw" ];
        };

        # Keep writable overlay from filling up
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };

        # OpenClaw service
        systemd.services.openclaw = {
          description = "OpenClaw AI Assistant Gateway";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          environment = {
            HOME = "/var/lib/openclaw";
            NODE_ENV = "production";
          };

          serviceConfig = {
            Type = "simple";
            User = "openclaw";
            Group = "openclaw";
            WorkingDirectory = "/var/lib/openclaw";
            ExecStart = "${lib.getExe pkgs.${namespace}.openclaw} gateway --bind 0.0.0.0 --port 18789";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        users.users.openclaw = {
          isSystemUser = true;
          group = "openclaw";
          home = "/var/lib/openclaw";
          createHome = true;
        };

        users.groups.openclaw = { };

        services.openssh = {
          enable = true;
          settings.PermitRootLogin = "no";
        };

        system.stateVersion = "24.11";
      };
    };
  };

  # ============================================================================
  # Nix Maintenance
  # ============================================================================

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "03:30" ];
  };

  # ============================================================================
  # System Version
  # ============================================================================

  system.stateVersion = "24.11";
}
