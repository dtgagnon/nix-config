{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.n8n;
in
{
  options.${namespace}.services.n8n = {
    enable = mkBoolOpt false "Enable the n8n service";
  };

  config = mkIf cfg.enable {
    services.n8n = {
      enable = true;
      openFirewall = false;
      # sets the environment variable WEBHOOK_URL for n8n, in case we're running behind a reverse proxy. This cannot be set through configuration and must reside in an environment variable.
      webhookUrl = "";
      # JSON values for configuration (see n8n docs)
      settings = { };
    };
  };
}
