{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.self-host;
in
{
  options.${namespace}.suites.self-host = {
    enable = mkBoolOpt false "Enable the self-hosted suite.";
  };

  config = mkIf cfg.enable {
    spirenix.services = {
      audiobookshelf = enabled;
      hoarder = enabled;
      home-assistant = enabled;
      immich = enabled;
			ntfy = enabled;
    };
  };
}
