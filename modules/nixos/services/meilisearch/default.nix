{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.meilisearch;
in
{
  options.${namespace}.services.meilisearch = {
    enable = mkBoolOpt false "Enable meilisearch";
    masterKeyFile = mkOpt (types.nullOr types.path) config.sops.secrets."meili-masterkey".path "Declare the master key file location";
    addr = mkOpt types.str "127.0.0.1" "Declare the directory to store the service data";
    port = mkOpt types.port 7700 "Declare the directory to store the service data";
  };

  config = mkIf cfg.enable {
    services.meilisearch = {
      enable = true;
      listenAddress = cfg.addr;
      listenPort = cfg.port;
      inherit (cfg) masterKeyFile;
    };

    sops.secrets."meili-masterkey" = { };
  };
}
