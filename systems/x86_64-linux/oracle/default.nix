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
        targetHost = "oracle";
      };
    };

    services = {
      openssh = enabled;
      tailscale = enabled;
      coolify = {
        enable = true;
        port = 8000;
        openFirewall = false; # Using Tailscale, no need to expose publicly
        autoUpdate = true;
      };
    };

    system = {
      enable = true;
      preservation = enabled;
    };

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };

    # No virtualization needed for VPS guest
    virtualisation.kvm.enable = false;
  };

  # Oracle VPS specific settings
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Enable serial console for Oracle Cloud Shell Access
  boot.kernelParams = [ "console=ttyS0,115200" "console=tty1" ];

  # Firewall configuration
  networking.firewall = {
    enable = true;
    # Tailscale manages network access, but keep SSH open for initial setup
    allowedTCPPorts = [ 22 ];
    # Allow Tailscale
    trustedInterfaces = [ "tailscale0" ];
  };

  system.stateVersion = "24.11";
}
