{ lib
, host
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
      gaming = enabled;
      networking = enabled;
    };

    apps = {
      proton = enabled;
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
      audio = enabled;
      davfs = enabled;
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
        lookingGlass.enable = true;
        vfio.enable = true;
        vfio.mode = "dynamic";
        diagnostics.enable = true;
      };
    };
  };

  sops.secrets = {
    # Loc
    city = { };
    elevation = { };
    latlong = { };

    # APIs
    anthropic_api = { };
    deepseek_api = { };
    moonshot_api = { };
    openai_api = { };
    openrouter_api = { };
  };

  system.stateVersion = "24.11";
}
