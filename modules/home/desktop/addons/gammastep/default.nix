{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.gammastep;
in
{
  options.${namespace}.desktop.addons.gammastep = {
    enable = mkBoolOpt false "Whether to enable gammastep blue light filter.";
    latitude = mkOpt types.str "45.5" "Your latitude for accurate sun times.";
    longitude = mkOpt types.str "-73.6" "Your longitude for accurate sun times.";
    temperature = {
      day = mkOpt types.int 6500 "Color temperature during the day (in Kelvin).";
      night = mkOpt types.int 3500 "Color temperature during the night (in Kelvin).";
    };
  };

  config = mkIf cfg.enable {
    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = cfg.latitude;
      longitude = cfg.longitude;
      temperature = {
        day = cfg.temperature.day;
        night = cfg.temperature.night;
      };
      settings = {
        general = {
          adjustment-method = "wayland";
          fade = 1;
        };
      };
    };
  };
}
