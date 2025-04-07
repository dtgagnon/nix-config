{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.ntfy;
in
{
  options.${namespace}.services.ntfy = {
    enable = mkBoolOpt false "Enable caddy for reverse-proxy";
  };

  config = mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      user = "ntfy";
      group = "ntfy";
      settings.base-url = "http://100.100.1.2";
    };
  };
}
