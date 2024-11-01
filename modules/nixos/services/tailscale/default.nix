{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.services.tailscale;
in
{
  options.services.tailscale = {
    enable = mkBoolOpt false "Enable tailscale";
    authKey = mkOpt types.str "" "Authentication key to authorize this node on the tailnet";
    hostname = mkOpt types.str config.networking.hostName "Hostname for this tailnet node";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      extraSetFlags = [ "--ssh" ];
    };

    # Define the tailscaled systemd service.
    systemd.services.tailscaled = {
      description = "Tailscale Daemon";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.tailscale}/bin/tailscaled";
        Restart = "on-failure";
        RestartSec = 5;
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Run tailscale up after the service starts.
    systemd.services.tailscale-up = {
      description = "Tailscale Up Script";
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.tailscale}/bin/tailscale up \
            --authkey=${config.services.tailscale.authKey} \
            --hostname=${config.services.tailscale.hostname}
        '';
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
