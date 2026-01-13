{ lib
, config
, namespace
, ...
}:
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
      arrs = enabled;
      gaming = enabled;
      networking = enabled;
      self-host = enabled;
    };

    apps = {
      proton = enabled;
    };

    desktop = {
      fonts = enabled;
      gnome = enabled;
      stylix = {
        enable = true;
        wallpaper = "hazy-purple-orange-sunset-palmtrees";
      };
    };

    security = {
      pam = enabled;
      sudo = enabled;
      sops-nix = {
        enable = true;
        targetHost = "spirepoint";
      };
      vpn = {
        tailscaleCompat = true;
        endpoint = "node-us-121.protonvpn.net:51820";
        peerPublicKey = "5vyz98gHBbT8z1bdNNZdGYAW0NJIgw1pgr+E6WlJPQA=";
      };
    };

    services = {
      audio = { enable = true; useMpd = true; };
      copyparty = enabled;
      odoo = enabled;
      nextcloud = enabled;
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
      # rustdesk = enabled; #TODO: Renable when rustdesk build failure is fixed
    };

    virtualisation.kvm.enable = false;
  };

  system.stateVersion = "24.11";
}
