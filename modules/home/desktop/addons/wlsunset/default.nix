{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.wlsunset;
in
{
  options.${namespace}.desktop.addons.wlsunset = {
    enable = mkBoolOpt false "Whether to enable wlsunset.";
    
    latitude = mkOpt types.str "45.5" "Your latitude for accurate sun times.";
    longitude = mkOpt types.str "-73.6" "Your longitude for accurate sun times.";
    
    temperature = {
      day = mkOpt types.int 6500 "Color temperature during the day (in Kelvin).";
      night = mkOpt types.int 3500 "Color temperature during the night (in Kelvin).";
    };

    gamma = mkOpt types.str "1.0" "Gamma correction value.";
    
    duration = mkOpt types.int 900 "Transition duration in seconds.";
  };

  config = mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      latitude = cfg.latitude;
      longitude = cfg.longitude;
      temperature = {
        day = cfg.temperature.day;
        night = cfg.temperature.night;
      };
      gamma = cfg.gamma;
      duration = cfg.duration;
    };
  };
}
