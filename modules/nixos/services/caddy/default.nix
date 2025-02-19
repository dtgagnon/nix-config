{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.caddy;
in
{
  options.${namespace}.services.caddy = {
    enable = mkBoolOpt false "Enable caddy for reverse-proxy";
    email = mkOpt (types.nullOr types.str) null "Email address used with ACME acct w/ the CA; highly recommended";
  };

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = pkgs.caddy;
      acmeCA = null; # "https://acme-v02.api.letsencrypt.org/directory"
      inherit (cfg) email;

      environmentFile = "/run/secrets/caddy";
      extraConfig = "";
      # globalConfig = ''
      #           				{
      #           					grace_period = 5s
      #   									acme_ca https://acme.zerossl.com/v2/DV90
      #   									acme_eab {
      #   										key_id {$EAB_KEY_ID}
      #   										mac_key {$EAB_MAC_KEY}
      #   									}
      #           				}
      #                   			'';

      virtualHosts = {
        #    "hydra.example.com" = {
        #      serverAliases = [ "www.hydra.example.com" ];
        #      extraConfig = ''
        # 	encode gzip
        # 	root * /srv/http
        # '';
        #    };
      };
    };
  };
}
