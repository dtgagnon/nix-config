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
      environment = {
        diagnostics = "false";
        versionNotifications = "false";
        templates = "true";
        hiringBanner = "false";
      };
      enable = true;
      openFirewall = false;
    };
  };
}
