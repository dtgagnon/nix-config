{ lib
, namespace
, pkgs
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

  spirenix = {
    suites = {
      headless = enabled;
      networking = enabled;
    };

    # Server mode - desktop removed
    hardware = {
      keyboard = enabled; # console keyboard layout (needed for physical access/recovery)
      laptop = enabled; # battery, lid, power management
    };

    security = {
      pam = enabled;
      sudo = enabled;
      sops-nix = enabled;
    };

    services = {
      coolify = enabled;

      caddy = {
        enable = true;
        email = "gagnon.derek@gmail.com";
        tailnetName = "aegean-interval";

        proxiedServices = {
          # Service directory/dashboard at spirenet.link
          dashboard = {
            backend = "http://localhost:8080";
            domain = "spirenet.link";
            useTailscale = false; # Public domain
          };
        };
      };
    };

    system.enable = true;
    system.preservation = {
      enable = true;
      extraSysDirs = [
        "/var/lib/coolify"
        "/var/lib/caddy"
        "/var/log/caddy"
        "/var/lib/fail2ban"
        "/var/log/audit"
        "/var/www"
      ];
    };

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };
  };

  # Simple website server
  systemd.services.simple-website = {
    description = "Simple static website";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python -m http.server 8080 --directory /var/www";
      Restart = "on-failure";
      User = "www-data";
      Group = "www-data";
    };
  };

  # Create www-data user
  users.users.www-data = {
    isSystemUser = true;
    group = "www-data";
  };
  users.groups.www-data = { };

  # Create website directory
  systemd.tmpfiles.rules = [
    "d /var/www 0755 www-data www-data - -"
  ];

  # Security hardening
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # 1 week max
    };
    ignoreIP = [
      "100.64.0.0/10" # Tailscale CGNAT range
      "192.168.0.0/16" # Local networks
    ];
  };

  # Automated security updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false; # Manual reboot for server
    dates = "03:00"; # 3 AM daily
    flake = "git+file:///persist/home/dtgagnon/nix-config?ref=main#slim";
    flags = [ "--refresh" "--print-build-logs" ];
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

  # auditd for intrusion detection
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      "-a always,exit -F arch=b64 -S execve -k exec"
      "-w /etc/passwd -p wa -k passwd_changes"
      "-w /etc/shadow -p wa -k shadow_changes"
      "-w /etc/ssh/sshd_config -p wa -k sshd_changes"
    ];
  };

  # Firewall configuration
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

  system.stateVersion = "24.11";
}
