{
  lib,
  namespace,
  pkgs,
  inputs,
  ...
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
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "sd_mod"
        "rtsx_usb_sdmmc"
      ];
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
      trustedInterfaces = [ "tailscale0" ];
    };

    # NAT for microVM internet access
    nat = {
      enable = true;
      internalInterfaces = [ "vm-openclaw" ];
      externalInterface = "wlp2s0";
    };

  };

  # Assign gateway IP to host side of VM tap (re-applied each time tap is recreated)
  # '+' prefix runs as root since the service user (microvm) lacks CAP_NET_ADMIN
  systemd.services."microvm@openclaw".serviceConfig.ExecStartPost =
    "+${pkgs.iproute2}/bin/ip addr replace 10.0.0.1/24 dev vm-openclaw";

  # ============================================================================
  # Spirenix Module Configuration
  # ============================================================================

  spirenix = {
    user.shell = pkgs.bash;

    suites = {
      headless = enabled;
      networking = enabled;
    };

    services.tailscale.authKeyFile = null; # Manual auth; no sops secret needed

    hardware = {
      keyboard = enabled;
      laptop = enabled;
    };

    security = {
      pam = enabled;
      sudo = enabled;
      sops-nix = enabled;
      vpn.enable = lib.mkForce false;
    };

    system.enable = true;
    system.preservation = {
      enable = true;
      extraSysDirs = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/microvms"
        "/var/lib/tailscale"
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

  systemd.services."microvm@openclaw".serviceConfig.TimeoutStopSec = 30;

  microvm = {
    host.enable = true;
    autostart = [ "openclaw" ];

    vms.openclaw = {
      pkgs = pkgs;
      config = {
        imports = [
          ({ lib, pkgs, config, ... }@args: import ../../../modules/nixos/services/openclaw (args // { namespace = "spirenix"; }))
        ];

        microvm = {
          hypervisor = "cloud-hypervisor";
          vcpu = 4;
          mem = 2560; # 2.5GB — host has 3.72GB total, leaves ~1.2GB headroom

          # Ephemeral tmpfs root; only declared volumes persist across reboots
          writableStoreOverlay = "/nix/.rw-store";

          volumes = [
            {
              image = "/var/lib/microvms/openclaw/openclaw-data.img";
              mountPoint = "/var/lib/openclaw";
              size = 20480; # 20GB — workspace, sessions, memory, downloads, caches
            }
            {
              image = "/var/lib/microvms/openclaw/tailscale.img";
              mountPoint = "/var/lib/tailscale";
              size = 256; # 256MB — identity + auth state
            }
          ];

          interfaces = [
            {
              type = "tap";
              id = "vm-openclaw";
              mac = "02:00:00:00:00:01";
            }
          ];

          # Share host's nix store read-only
          shares = [
            {
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              tag = "ro-store";
              proto = "virtiofs";
            }
          ];
        };

        # VM's internal NixOS configuration
        networking = {
          hostName = "openclaw";
          useNetworkd = true;
          useDHCP = false;
        };

        systemd.network.networks."10-eth0" = {
          matchConfig.Name = "e*";
          addresses = [ { Address = "10.0.0.2/24"; } ];
          routes = [ { Gateway = "10.0.0.1"; } ];
          dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
        };

        environment.systemPackages = [
          pkgs.ghostty.terminfo
          pkgs.nodejs_22 # required for `openclaw plugins install`
        ];

        spirenix.services.openclaw = {
          enable = true;
          bindAddress = "tailnet";
        };

        # Enable flakes for per-task environments
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [ "openclaw" ];
        };

        # Keep writable overlay from filling up
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };

        services.tailscale = {
          enable = true;
          extraSetFlags = [ "--exit-node=" "--ssh" ];
        };

        # TODO: remove after Tailscale SSH is confirmed working
        services.openssh = {
          enable = true;
          settings.PermitRootLogin = "prohibit-password";
        };
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAkkyCzK0fKyp0+gCR48AV3pq9XOggryd8dXS/7uobUi user=dtgagnon"
        ];

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

  system.stateVersion = "26.05";
}
