{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.authentik;
in
{
  options.${namespace}.services.authentik = {
    enable = mkEnableOption "Authentik identity provider (using authentik-nix)";

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "auth.example.com";
      description = "Domain name for Authentik web interface (required if nginx.enable is true)";
    };

    nginx = {
      enable = mkBoolOpt false "Enable nginx reverse proxy with ACME (disable if using Pangolin/external proxy)";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address for Authentik to listen on (0.0.0.0 for Tailscale/external access, 127.0.0.1 for local only)";
    };

    port = mkOption {
      type = types.port;
      default = 9000;
      description = "HTTP port for Authentik web interface";
    };

    email = {
      enable = mkBoolOpt false ''
        Enable email support. Requires these secrets in sops:
        - authentik/email-host (SMTP server)
        - authentik/email-port (usually 587)
        - authentik/email-username
        - authentik/email-password
        - authentik/email-from (sender address)
        - authentik/email-use-tls (true/false)
      '';
    };

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Additional settings passed to services.authentik.settings";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.nginx.enable || cfg.domain != null;
        message = "spirenix.services.authentik.domain must be set when nginx.enable is true";
      }
    ];

    # Create static user/group for authentik (required for persistence compatibility)
    # DynamicUser doesn't work with bind-mounted state directories
    users = {
      users.authentik = {
        isSystemUser = true;
        group = "authentik";
        home = "/var/lib/authentik";
      };
      groups.authentik = { };
    };

    systemd = {
      # Override services to use static user instead of DynamicUser
      services =
        let
          staticUserOverride = {
            serviceConfig = {
              DynamicUser = lib.mkForce false;
              User = "authentik";
              Group = "authentik";
            };
          };
        in
        {
          authentik = staticUserOverride;
          authentik-worker = staticUserOverride;
          authentik-migrate = staticUserOverride;
        };

      # Ensure state directory has correct ownership
      tmpfiles.rules = [
        "d /var/lib/authentik 0750 authentik authentik -"
      ];
    };

    # Sops secrets for Authentik
    sops.secrets = lib.mkMerge [
      # Required secrets
      {
        "authentik/secret-key" = { }; # generate with `openssl rand -base64 50`
        "authentik/bootstrap-password" = { };
        "authentik/bootstrap-email" = { };
      }

      # Email secrets (only when email.enable = true)
      (mkIf cfg.email.enable {
        "authentik/email-host" = { };
        "authentik/email-port" = { };
        "authentik/email-username" = { };
        "authentik/email-password" = { };
        "authentik/email-from" = { };
        "authentik/email-use-tls" = { };
      })
    ];

    # Generate environment file from sops secrets
    sops.templates."authentik-env" = {
      content =
        ''
          AUTHENTIK_SECRET_KEY=${config.sops.placeholder."authentik/secret-key"}
          AUTHENTIK_BOOTSTRAP_PASSWORD=${config.sops.placeholder."authentik/bootstrap-password"}
          AUTHENTIK_BOOTSTRAP_EMAIL=${config.sops.placeholder."authentik/bootstrap-email"}
        ''
        + lib.optionalString cfg.email.enable ''
          AUTHENTIK_EMAIL__HOST=${config.sops.placeholder."authentik/email-host"}
          AUTHENTIK_EMAIL__PORT=${config.sops.placeholder."authentik/email-port"}
          AUTHENTIK_EMAIL__USERNAME=${config.sops.placeholder."authentik/email-username"}
          AUTHENTIK_EMAIL__PASSWORD=${config.sops.placeholder."authentik/email-password"}
          AUTHENTIK_EMAIL__FROM=${config.sops.placeholder."authentik/email-from"}
          AUTHENTIK_EMAIL__USE_TLS=${config.sops.placeholder."authentik/email-use-tls"}
        '';
      owner = "authentik";
      group = "authentik";
      mode = "0400";
    };

    # Configure authentik-nix
    services.authentik = {
      enable = true;
      createDatabase = true;
      environmentFile = config.sops.templates."authentik-env".path;

      settings = {
        # Disable anonymous telemetry
        disable_startup_analytics = true;
        avatars = "initials";

        # Listen configuration
        listen = {
          http = "${cfg.listenAddress}:${toString cfg.port}";
        };
      } // cfg.settings;

      nginx = mkIf cfg.nginx.enable {
        enable = true;
        enableACME = true;
        host = cfg.domain;
      };
    };

    # Persist authentik data when using preservation/impermanence
    ${namespace}.system.preservation.extraSysDirs = [
      "var/lib/authentik"
    ];
  };
}
