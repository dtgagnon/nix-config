{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.tailscale;
in
{
  options.${namespace}.services.tailscale = {
    enable = mkBoolOpt false "Enable tailscale";
    authKeyDir = mkOpt types.str "cat ${config.sops.secrets."tailscale-authKey".path}" "Authentication key to authorize this node on the tailnet";
    hostname = mkOpt types.str config.networking.hostName "Hostname for this tailnet node";
  };

  config = mkIf cfg.enable {

    sops.secrets = {
      "tailscale-authKey" = {
        owner = config.${namespace}.user.name;
      };
    };

    services.tailscale = {
      enable = true;
      extraSetFlags = [ "--ssh" ];
      authKeyFile = cfg.authKeyDir;
    };
  };
}
