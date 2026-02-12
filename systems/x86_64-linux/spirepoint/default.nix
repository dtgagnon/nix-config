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
      audio = enabled;
      nfs = {
        enable = true;
        exports = [
          "/srv/media/music 100.100.1.0/24(ro,sync,no_subtree_check,no_root_squash)"
        ];
        openFirewall = true;
      };
      authentik = {
        enable = true;
        domain = "auth.spirenet.link";
        # nginx.enable = false; # Using Pangolin via oranix
        # listenAddress = "0.0.0.0"; # Default - accessible via Tailscale
        # port = 9000; # Default
      };
      copyparty = enabled;
      odoo = enabled;
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
