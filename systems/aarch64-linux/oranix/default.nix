{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [
    ./hardware.nix
    ./disk-config.nix
  ];

  spirenix = {
    suites = {
      networking = enabled;
    };

    security = {
      pam = enabled;
      sudo = enabled;
      sops-nix = {
        enable = true;
        targetHost = "oranix";
      };
    };

    services = {
      openssh = enabled;
      tailscale = enabled;

      # Pangolin - tunneled reverse proxy (public ingress)
      # pangolin = {
      #   enable = true;
      #   baseDomain = "yourdomain.com";  # TODO: Set your domain
      #   email = "you@example.com";       # TODO: Set your email
      # };

      # Rybbit - privacy-focused analytics
      # rybbit = {
      #   enable = true;
      #   useBuiltinProxy = false;  # Pangolin handles ingress
      # };

      # coolify = {
      #   enable = true;
      #   port = 8000;
      #   openFirewall = false; # Using Tailscale, no need to expose publicly
      #   autoUpdate = true;
      # };
    };

    system = {
      enable = true;
      preservation = enabled;
    };

    tools = {
      # comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };

    # No virtualization needed for VPS guest
    virtualisation.kvm.enable = false;
  };

  # Oracle Ampere A1 uses UEFI boot
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Enable serial console for Oracle Cloud Shell Access
  boot.kernelParams = [
    "console=ttyAMA0,115200"
    "console=tty1"
  ];

  # Firewall configuration
  networking.firewall = {
    enable = true;
    # Tailscale manages network access, but keep SSH open for initial setup
    allowedTCPPorts = [ 22 ];
    # Allow Tailscale
    trustedInterfaces = [ "tailscale0" ];
  };

  # Automated Maintenance disabled - using push-based deployment via deploy-rs
  # This avoids needing private SSH keys on the VPS for fetching private flake inputs
  system.autoUpgrade.enable = false;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = lib.mkForce "--delete-older-than 7d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "03:30" ];
  };

  system.stateVersion = "25.11";
}
