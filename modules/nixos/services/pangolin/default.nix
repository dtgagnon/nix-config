{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.${namespace}.services.pangolin;
in
{
  options.${namespace}.services.pangolin = {
    enable = mkEnableOption "Pangolin tunneled reverse proxy with identity and access management";

    baseDomain = mkOption {
      type = types.str;
      description = "Base domain for Pangolin (e.g., 'example.com'). Services will be subdomains of this.";
      example = "example.com";
    };
  };

  config = mkIf cfg.enable {
    # Override upstream's fossorial group with pangolin
    users.users.pangolin.group = lib.mkForce "pangolin";
    users.groups.pangolin = { };

    # Sops secrets:
    #   pangolin/env: SERVER_SECRET (min 32 chars), optionally CF_DNS_API_TOKEN, EMAIL_SMTP_PASS
    #   pangolin/acme-email: Email address for Let's Encrypt registration
    sops.secrets."pangolin/env" = {
      owner = "pangolin";
      group = "pangolin";
      mode = "0400";
    };

    sops.secrets."pangolin/acme-email" = { };

    services.pangolin = {
      enable = true;
      baseDomain = cfg.baseDomain;
      dashboardDomain = "pangolin.${cfg.baseDomain}";
      # Use sops placeholder - will be substituted in the template
      letsEncryptEmail = config.sops.placeholder."pangolin/acme-email";
      openFirewall = true;
      environmentFile = config.sops.secrets."pangolin/env".path;
    };

    # Use sops template to generate traefik config with real ACME email
    sops.templates."traefik-config.toml" = {
      content = builtins.readFile config.services.traefik.staticConfigFile;
      owner = "root";
      group = "root";
      mode = "0644";
    };

    # Override Traefik to use the sops-rendered config
    systemd.services.traefik = {
      after = [ "sops-nix.service" ];
      serviceConfig.ExecStart = lib.mkForce "${pkgs.traefik}/bin/traefik --configfile=${config.sops.templates."traefik-config.toml".path}";
    };
  };
}
