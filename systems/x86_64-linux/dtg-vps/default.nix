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
        targetHost = "dtg-vps";
      };
    };

    services = {
      openssh = {
        enable = true;
        # Use VPS-specific SSH key for better security isolation
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMufoZHNO9uC/uR+6G3ww+JwqHekXN/xNlG26qlUNsJe dtgagnon@dtg-vps"
        ];
      };

      tailscale = enabled;

      # Nginx reverse proxy for Odoo
      nginx = {
        enable = true;
        # TODO: Replace with your actual email address
        email = "your-email@example.com";

        baseDomain = "dtgengineering.com";

        proxiedServices = {
          odoo = {
            # TODO: Replace with your Odoo server's Tailscale IP
            # Find it by running: tailscale status
            backend = "http://100.x.x.x:8069";

            domain = "dtgengineering.com";

            # Odoo requires WebSocket support for real-time features
            enableWebSocket = true;

            # Odoo can handle large file uploads (documents, images, etc.)
            clientMaxBodySize = "100M";

            # Odoo operations can be slow, especially with large databases
            proxyTimeout = 300;

            # Standard SSL/ACME settings
            enableSSL = true;
            forceSSL = true;
            enableACME = true;

            # Optional: Add custom headers if needed
            customHeaders = {
              "X-Frame-Options" = "SAMEORIGIN";
              "X-Content-Type-Options" = "nosniff";
              "X-XSS-Protection" = "1; mode=block";
            };
          };
        };

        # Enable recommended security settings
        recommendedSettings = true;
        enableHTTP2 = true;
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

  # Firewall configuration
  networking = {
    hostName = "dtg-vps";

    firewall = {
      enable = true;

      # HTTP, HTTPS, and SSH
      allowedTCPPorts = [ 80 443 22 ];

      # Tailscale interface is trusted
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  # System state version - keep this consistent
  system.stateVersion = "24.11";
}
