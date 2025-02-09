{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.arr;
in
{
  options.${namespace}.suites.arr = {
    enable = mkBoolOpt false "Enable the arr suite configuration";
  };

  config = mkIf cfg.enable {
    spirenix.services.media = {
      bazarr = enabled;
      lidarr = enabled;
      prowlarr = enabled;
      radarr = enabled;
      readarr = enabled;
      sonarr = enabled;
    };
  };
}