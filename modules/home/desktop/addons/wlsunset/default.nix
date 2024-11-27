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
    
    latitude = mkOpt types.float 42.3 "Your current latitude, between -90.0 and 90.0";
    longitude = mkOpt types.float -83.0 "Your current longitude, between -180.0 and 180.0";
    
    temperature = {
      day = mkOpt types.int 6500 "Colour temperature to use during the day, in Kelvin (K)";
      night = mkOpt types.int 4500 "Colour temperature to use during the night, in Kelvin (K)";
    };

    gamma = mkOpt types.float 1.0 "Gamma value to use";
    
    sunrise = mkOpt (types.nullOr types.str) null "The time when the sun rises (in 24 hour format)";
    sunset = mkOpt (types.nullOr types.str) null "The time when the sun sets (in 24 hour format)";
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
      sunrise = cfg.sunrise;
      sunset = cfg.sunset;
    };
  };
}
