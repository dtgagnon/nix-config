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
  cfg = config.${namespace}.services.matrix;
in
{
  options.${namespace}.services.matrix = {
    enable = mkEnableOption "Tuwunel Matrix homeserver (lightweight Rust Matrix server)";

    serverName = mkOption {
      type = types.str;
      example = "matrix.spirenet.link";
      description = ''
        The Matrix server_name — used as the suffix for all user and room IDs
        (e.g. @user:matrix.spirenet.link). This must match the public hostname
        behind the reverse proxy.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 6167;
      description = "Local port tuwunel listens on (reverse-proxied by Pangolin/Traefik).";
    };

    federation = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Matrix federation with other homeservers.";
      };

      trustedServers = mkOption {
        type = types.listOf types.str;
        default = [ "matrix.org" ];
        description = ''
          Trusted key servers for room key lookups.
          When federation is disabled, this is ignored and set to an empty list.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.matrix-tuwunel = {
      enable = true;

      settings.global = {
        server_name = cfg.serverName;

        # Bind to localhost only — Pangolin/Traefik handles external TLS termination.
        # Add a Pangolin resource via the dashboard pointing to 127.0.0.1:<port>.
        address = [ "127.0.0.1" ];
        port = [ cfg.port ];

        # Closed, invite-only server — no public self-registration.
        # Admin creates accounts via: `tuwunel-admin users create <name> <password>`
        allow_registration = false;

        # Federation controls whether this server can talk to other homeservers.
        allow_federation = cfg.federation.enable;

        # Allow end-to-end encrypted rooms.
        allow_encryption = true;

        trusted_servers = if cfg.federation.enable then cfg.federation.trustedServers else [ ];
      };
    };
  };
}
