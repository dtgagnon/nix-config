{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types mapAttrs' nameValuePair;
  cfg = config.${namespace}.services.static-sites;

  # Submodule for individual site configuration
  siteType = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        description = "Package containing the static site files (should be a directory with index.html)";
      };

      port = mkOption {
        type = types.port;
        description = "Port to serve the site on (localhost only)";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra arguments to pass to darkhttpd";
        example = [ "--mimetypes" "/etc/mime.types" ];
      };
    };
  };

  # Generate systemd service for a site
  mkSiteService = name: siteCfg: {
    description = "Static site server for ${name}";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      ExecStart = ''
        ${pkgs.darkhttpd}/bin/darkhttpd ${siteCfg.package} \
          --port ${toString siteCfg.port} \
          --addr 127.0.0.1 \
          --no-listing \
          ${lib.escapeShellArgs siteCfg.extraArgs}
      '';
      Restart = "on-failure";
      RestartSec = "5s";

      # Security hardening
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
    };
  };
in
{
  options.${namespace}.services.static-sites = {
    enable = mkEnableOption "static site hosting with darkhttpd";

    sites = mkOption {
      type = types.attrsOf siteType;
      default = { };
      description = ''
        Attribute set of static sites to serve.
        Each site gets its own darkhttpd instance on localhost.
        Use Pangolin to route external domains to these ports.
      '';
      example = lib.literalExpression ''
        {
          dtge = {
            package = inputs.dtge.packages.''${pkgs.system}.default;
            port = 8080;
          };
          blog = {
            package = pkgs.my-blog;
            port = 8081;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Create a systemd service for each site
    systemd.services = mapAttrs'
      (name: siteCfg: nameValuePair "static-site-${name}" (mkSiteService name siteCfg))
      cfg.sites;

    # Useful assertion
    assertions = [
      {
        assertion = cfg.sites != { };
        message = "static-sites: At least one site must be defined when enabled";
      }
    ];
  };
}
