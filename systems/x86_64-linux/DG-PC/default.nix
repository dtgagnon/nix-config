{ lib
, host
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

  networking.hostName = host;

  spirenix = {
    suites = {
      networking = enabled;
    };

    apps = {
      bottles = enabled;
      steam = enabled;
      windows-apps = enabled;
    };

    desktop = {
      fonts = enabled;
      hyprland = enabled;
      stylix = enabled;
    };

    security = {
      sudo = enabled;
      sops-nix = enabled;
    };

    services = {
      audio = {
        enable = true;
        useMpd = true;
        mpd.musicDir = "/home/dtgagnon/Music";
      };
      nfs = {
        enable = true;
        mounts.spirepoint-music = {
          server = "100.100.1.2";
          remotePath = "/srv/media/music";
          mountPoint = "/home/dtgagnon/Music";
        };
      };
      # apollo = enabled;
      keyd = enabled;
      n8n = enabled;
      # llama-cpp = enabled; # Replaced Ollama with llama.cpp + llama-swap
      ollama = enabled; # Disabled in favor of llama-cpp
      openwebui = enabled;
      openssh.manage-other-hosts = false;
    };

    system = {
      enable = true;
      environment.sessionVariables = {
        CODEX_HOME = "$HOME/.config/codex";
      };
      preservation = enabled;
    };

    tools = {
      comma = enabled;
      general = enabled;
      monitoring = enabled;
      nix-ld = enabled;
      rustdesk = enabled;
    };

    # topology.self.hardware.info = "DG-PC";

    virtualisation = {
      podman = enabled;
      kvm = {
        enable = true;
        vmDomains = [ "win11-GPU" ];
        lookingGlass = {
          enable = true;
          kvmfrSize = [ 256 ];
        };
        vfio.enable = true;
        vfio.dgpuBootCfg = "host";
        diagnostics.enable = true;
      };
    };
  };

  sops.secrets = {
    city = { };
    elevation = { };
    latlong = { };

    deepseek_api = { };
    moonshot_api = { };
    openai_api = { };
    openrouter_api = { };
  };

  system.stateVersion = "24.11";
}
