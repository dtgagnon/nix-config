{ lib
, pkgs
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
      package = pkgs.tailscale.overrideAttrs { doCheck = false; };
      extraSetFlags = [ "--ssh" ]; # only use "--accept-routes" when you want to access devices on a REMOTE physical LAN
      inherit (cfg) authKeyFile;
    };
  };
}
