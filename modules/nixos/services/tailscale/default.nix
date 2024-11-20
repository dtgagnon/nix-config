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
    authKeyFile = mkOpt types.str "/run/secrets/tailscale-authKey" "Authentication key to authorize this node on the tailnet";
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
      inherit (cfg) authKeyFile;
    };
  };
}
