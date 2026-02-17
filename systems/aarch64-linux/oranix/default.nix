{ config, lib, namespace, inputs, system, ... }:
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
      crowdsec = enabled;
    };

    services = {
      openssh = enabled;
      tailscale = enabled;

      pangolin = {
        enable = true;
        baseDomain = "spirenet.link";
        geoBlocking.enable = true;
        # Allow CORS from Tailnet for direct dashboard access
        extraCorsOrigins = [ "http://100.100.90.1:3002" ];
      };

      rybbit = {
        enable = true;
        domain = "analytics.spirenet.link";
        useBuiltinProxy = false;
      };

      # Websites served behind Pangolin
      websites = {
        enable = true;
        node = {
          dtge = {
            package = inputs.dtge.packages.${system}.default;
            entrypoint = "lib/dtge/dist/server/entry.mjs";
            port = 10000;
            environmentFile = config.sops.secrets.dtge-env.path;
          };
          portfolio = {
            package = inputs.portfolio.packages.${system}.default;
            port = 10002;
            environmentFile = config.sops.secrets.portfolio-env.path;
          };
        };
        static = {
          eterna-design = {
            package = inputs.eterna-design.packages.${system}.default;
            port = 10001;
          };
          spirenet-dashboard = {
            package = inputs.spirenet-dashboard.packages.${system}.default;
            port = 10003;
          };
        };
      };
    };

    system = {
      enable = true;
      preservation = enabled;
    };

    tools = {
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Enable serial console for OCI Shell Access
  boot.kernelParams = [
    "console=ttyAMA0,115200"
    "console=tty1"
  ];

  security.sudo.wheelNeedsPassword = lib.mkForce true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = lib.mkForce "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = [ "03:30" ];
    };
  };

  sops.secrets.dtge-env = { };
  sops.secrets.portfolio-env = { };

  system.stateVersion = "25.11";
}
