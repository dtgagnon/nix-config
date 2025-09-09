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
      proton-cloud = enabled;
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
      davfs = enabled;
      keyd = enabled;
      n8n = enabled;
      ollama = enabled;
      openwebui = enabled;
      openssh.manage-other-hosts = false;
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
