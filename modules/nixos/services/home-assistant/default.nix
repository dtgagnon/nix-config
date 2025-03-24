{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.home-assistant;
in
{
  options.${namespace}.services.home-assistant = {
    enable = mkBoolOpt false "Enable the home-assistant service";
    configDir = mkOpt types.str "/var/lib/hass" "The home assistant (hass) configuration directory";
  };

  config = mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      package = pkgs.home-assistant.overrideAttrs (_oldAttrs: { doInstalLCheck = false; });
      openFirewall = false;

      extraArgs = [ ];

      # defaultIntegrations = [ ];

      extraPackages = python3Packages: with python3Packages; [
        # Packages to add to propagatedBuildInputs
        # postgresql support
        ## psycopg2 for example
      ];

      extraComponents = [
        "met"
        "openweathermap"
        "radio_browser"
        "sonarr"
        "radarr"
        "glances"
        "lifx"
      ];
      customComponents = [ ];

      inherit (cfg) configDir;
      configWritable = true;
      config = {
        homeassistant = {
          name = "Home";
          country = "US";
          currency = "USD";
          latitude = config.sops.secrets."home-assistant/latitude".path;
          longitude = config.sops.secrets."home-assistant/longitude".path;
          elevation = config.sops.secrets."home-assistant/elevation".path;
          unit_system = "us_customary";
          temperature_unit = "F";
          time_zone = "America/Detroit";
        };
        frontend = {
          themes = "";
        };
        http = {
          server_host = [ "100.100.1.2" ];
          server_port = 8123;
        };
        feedreader.urls = [ "https://nixos.org/blogs.xml" ];
      };

      customLovelaceModules = [ ];
      lovelaceConfigWritable = false;
      lovelaceConfig = {
        title = "Home";
        views = [
          {
            path = "default_view";
            title = "Home";
            cards = [
              {
                type = "light";
                entity = "";
                name = "";
              }
              {
                type = "sensor";
                entity = "";
                graph = "line";
              }
              {
                type = "weather-forecast";
                entity = "weather.home";
                show_forecast = true;
              }
            ];
          }
        ];
      };
    };

    sops.secrets = {
      "home-assistant/latitude".owner = "hass";
      "home-assistant/longitude".owner = "hass";
      "home-assistant/elevation".owner = "hass";
    };
  };
}
