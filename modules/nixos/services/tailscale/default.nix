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
    authKey = mkOpt types.str "cat ${config.sops.secrets."tailscale-authkey".path}" "Authentication key to authorize this node on the tailnet";
    hostname = mkOpt types.str config.networking.hostName "Hostname for this tailnet node";
  };

  config = mkIf cfg.enable {

    sops.secrets = {
      "tailscale-authkey" = {
        owner = config.${namespace}.user.name;
        inherit (config.${namespace}.user.name) group;
      };
    };

    services.tailscale = {
      enable = true;
      extraSetFlags = [ "--ssh" ];
      authKey = cfg.authKey;
    };
  };
}
