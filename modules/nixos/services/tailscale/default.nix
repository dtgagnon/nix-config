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
    authKeyDir = mkOpt types.str "" "Authentication key to authorize this node on the tailnet";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "tailscale-authKey" = {
        owner = config.${namespace}.user.name;
      };
    };

    services.tailscale = {
      enable = true;
      extraSetFlags = [ "--ssh" "--accept-routes" ];
      # authKeyFile = cfg.authKeyDir;
      authKeyFile = "/run/secrets/tailscale-authKey";
    };
  };
}
