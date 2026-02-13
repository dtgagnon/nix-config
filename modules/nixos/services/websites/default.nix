{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types mapAttrs' nameValuePair;
  cfg = config.${namespace}.services.websites;

  # --- Submodule types ---

  staticSiteType = types.submodule {
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

  nodeSiteType = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        description = "Package containing the Node.js app (should have a server.js entrypoint)";
      };

      port = mkOption {
        type = types.port;
        description = "Port to serve the app on (localhost only)";
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to an EnvironmentFile containing secrets (e.g. from sops-nix)";
      };
    };
  };

  # --- Service generators ---

  mkStaticService = name: siteCfg: {
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

  mkNodeService = name: siteCfg: {
    description = "Node.js app server for ${name}";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      HOSTNAME = "127.0.0.1";
      PORT = toString siteCfg.port;
      NODE_ENV = "production";
    };

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      ExecStart = "${pkgs.nodejs_24}/bin/node ${siteCfg.package}/server.js";
      Restart = "on-failure";
      RestartSec = "5s";
      WorkingDirectory = siteCfg.package;

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
      LockPersonality = true;
    } // lib.optionalAttrs (siteCfg.environmentFile != null) {
      EnvironmentFile = siteCfg.environmentFile;
    };
  };

  hasStatic = cfg.static != { };
  hasNode = cfg.node != { };
in
{
  options.${namespace}.services.websites = {
    enable = mkEnableOption "website hosting";

    static = mkOption {
      type = types.attrsOf staticSiteType;
      default = { };
      description = ''
        Static sites served via darkhttpd on localhost.
        Use Pangolin to route external domains to these ports.
      '';
      example = lib.literalExpression ''
        {
          dtge = {
            package = inputs.dtge.packages.''${pkgs.system}.default;
            port = 8080;
          };
        }
      '';
    };

    node = mkOption {
      type = types.attrsOf nodeSiteType;
      default = { };
      description = ''
        Node.js application servers on localhost.
        Each app runs its own server.js process.
        Use Pangolin to route external domains to these ports.
      '';
      example = lib.literalExpression ''
        {
          portfolio = {
            package = inputs.my-portfolio.packages.''${pkgs.system}.default;
            port = 10002;
            environmentFile = config.sops.secrets."portfolio/env".path;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services =
      (mapAttrs'
        (name: siteCfg: nameValuePair "website-static-${name}" (mkStaticService name siteCfg))
        cfg.static)
      //
      (mapAttrs'
        (name: siteCfg: nameValuePair "website-node-${name}" (mkNodeService name siteCfg))
        cfg.node);

    assertions = [
      {
        assertion = hasStatic || hasNode;
        message = "websites: At least one site must be defined when enabled";
      }
    ];
  };
}
