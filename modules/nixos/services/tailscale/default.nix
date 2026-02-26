{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkMerge mkIf types mapAttrsToList;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.tailscale;

  # Generate serve/funnel commands for each entry
  mkServeCommands = name: entry:
    let
      target =
        if entry.path != null then "${entry.path}"
        else if entry.proxy != null then entry.proxy
        else throw "Serve entry '${name}' must specify either 'path' or 'proxy'";
      serveCmd =
        if entry.funnel
        then "tailscale funnel --bg --https=${toString entry.https} ${target}"
        else "tailscale serve --bg --https=${toString entry.https} ${target}";
    in
    serveCmd;
in
{
  options.${namespace}.services.tailscale = {
    enable = mkBoolOpt false "Enable tailscale";
    exitNode = mkBoolOpt false "Advertise this node as a Tailscale exit node";
    authKeyFile = mkOpt (types.nullOr types.str) "/run/secrets/tailscale-authKey" "Authentication key to authorize this node on the tailnet. Set to null for manual authentication.";

    serve = mkOpt
      (types.attrsOf (types.submodule {
        options = {
          path = mkOpt (types.nullOr types.path) null "Local filesystem path to serve (for static files)";
          proxy = mkOpt (types.nullOr types.str) null "URL to proxy to (e.g., http://127.0.0.1:8080)";
          funnel = mkBoolOpt false "Enable public Funnel access (exposes to internet)";
          https = mkOpt types.port 443 "HTTPS port to serve on";
        };
      }))
      { } ''
      Attribute set of services to expose via Tailscale Serve/Funnel.

      Example:
        serve = {
          dashboard = {
            path = pkgs.my-static-site;  # Serve static files
            funnel = true;               # Make publicly accessible
          };
          api = {
            proxy = "http://127.0.0.1:3000";  # Proxy to local service
            funnel = false;                    # Tailnet only
          };
        };
    '';
  };

  config = mkMerge [
    (mkIf cfg.enable {
      sops.secrets = mkIf (cfg.authKeyFile != null) {
        "tailscale-authKey" = {
          owner = config.${namespace}.user.name;
        };
      };

      services.tailscale = {
        enable = true;
        package = pkgs.tailscale.overrideAttrs { doCheck = false; };
        extraSetFlags = [ "--ssh" ]
          ++ lib.optional cfg.exitNode "--advertise-exit-node";
        authKeyFile = lib.mkIf (cfg.authKeyFile != null) cfg.authKeyFile;
      };

      # Exit nodes need IP forwarding enabled
      boot.kernel.sysctl = mkIf cfg.exitNode {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };
    })

    # Configure Tailscale Serve/Funnel
    (mkIf (cfg.enable && cfg.serve != { }) {
      systemd.services.tailscale-serve = {
        description = "Configure Tailscale Serve/Funnel";
        after = [ "tailscaled.service" ];
        wants = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart =
            let
              commands = mapAttrsToList mkServeCommands cfg.serve;
            in
            pkgs.writeShellScript "tailscale-serve-setup" ''
              # Wait for tailscale to be ready
              until tailscale status --json | ${pkgs.jq}/bin/jq -e '.BackendState == "Running"' > /dev/null 2>&1; do
                sleep 1
              done

              # Reset any existing serve config
              tailscale serve reset || true

              # Configure each serve entry
              ${lib.concatStringsSep "\n" commands}
            '';
          ExecStop = "${pkgs.tailscale}/bin/tailscale serve reset";
        };
      };
    })

    # Add CORS origins for LLM services Ollama is enabled
    (mkIf config.services.ollama.enable {
      spirenix.services.ollama.allowedOrigins = [ "http://100.100.1.2" ];
    })
  ];
}
