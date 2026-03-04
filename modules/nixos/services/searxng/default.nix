{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.searxng;
in
{
  options.${namespace}.services.searxng = {
    enable = mkBoolOpt false "Enable SearXNG meta-search engine";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for SearXNG to listen on";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address for SearXNG to bind to (127.0.0.1 for local/proxied, 0.0.0.0 for all interfaces)";
    };

    openFirewall = mkBoolOpt false "Open firewall port for SearXNG";

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Additional SearXNG settings merged into services.searx.settings";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."searxng-env" = {
      owner = "searx";
      mode = "0400";
    };

    services.searx = {
      enable = true;
      environmentFile = config.sops.secrets."searxng-env".path;
      settings = {
        use_default_settings = true;
        server = {
          secret_key = "@SEARX_SECRET_KEY@";
          bind_address = cfg.listenAddress;
          port = cfg.port;
        };
        search.formats = [ "html" "json" ];
      } // cfg.settings;
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
