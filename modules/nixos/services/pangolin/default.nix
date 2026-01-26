{ lib
, config
, namespace
, ...
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

    email = mkOption {
      type = types.str;
      description = "Email for Let's Encrypt certificate registration.";
      example = "admin@example.com";
    };
  };

  config = mkIf cfg.enable {
    # Sops secret containing sensitive env vars:
    # Required: SERVER_SECRET (min 32 chars, encryption key)
    # Optional: EMAIL_SMTP_PASS (if using email features)
    # Optional: CF_DNS_API_TOKEN or other DNS provider creds (for wildcard certs)
    sops.secrets.pangolin-env = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    services.pangolin = {
      enable = true;
      baseDomain = cfg.baseDomain;
      dashboardDomain = "pangolin.${cfg.baseDomain}";
      letsEncryptEmail = cfg.email;
      openFirewall = true;
      environmentFile = config.sops.secrets.pangolin-env.path;
    };
  };
}
