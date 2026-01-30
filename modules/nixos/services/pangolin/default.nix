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

    sops.secrets."pangolin/acme-email" = {
      owner = "pangolin";
      group = "pangolin";
      mode = "0400";
    };

    services.pangolin = {
      enable = true;
      baseDomain = cfg.baseDomain;
      dashboardDomain = "pangolin.${cfg.baseDomain}";
      # Placeholder - patched by preStart after config is generated
      letsEncryptEmail = "__PANGOLIN_ACME_EMAIL__";
      openFirewall = true;
      environmentFile = config.sops.secrets."pangolin/env".path;
    };

    # Patch ACME email into traefik config after pangolin generates it
    systemd.services.pangolin = {
      preStart = lib.mkAfter ''
        # Wait for config file to exist (created by upstream preStart)
        TRAEFIK_CONFIG="/var/lib/pangolin/config/traefik/traefik_config.yml"
        if [ -f "$TRAEFIK_CONFIG" ] && [ -f "${config.sops.secrets."pangolin/acme-email".path}" ]; then
          EMAIL=$(${pkgs.coreutils}/bin/cat "${config.sops.secrets."pangolin/acme-email".path}" | ${pkgs.coreutils}/bin/tr -d '\n')
          ${pkgs.gnused}/bin/sed -i "s|__PANGOLIN_ACME_EMAIL__|$EMAIL|g" "$TRAEFIK_CONFIG"
        fi
      '';
    };
  };
}
