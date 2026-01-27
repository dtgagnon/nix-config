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

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Enable serial console for Oracle Cloud Shell Access
  boot.kernelParams = [
    "console=ttyAMA0,115200"
    "console=tty1"
  ];

  security.sudo.wheelNeedsPassword = lib.mkForce true;

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };

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
