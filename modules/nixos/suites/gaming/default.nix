{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;
  cfg = config.${namespace}.suites.gaming;
in
{
  options.${namespace}.suites.gaming = {
    enable = mkBoolOpt false "Enable the gaming suite";
  };

  config = mkIf cfg.enable {
    spirenix = {
      apps = {
        bottles = enabled;
        lutris = enabled;
        steam = enabled;
        proton = enabled;
        wine = enabled;
      };
    };
  };
}
