{ lib
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

  config = lib.mkMerge [
    (mkIf cfg.enable {
      services.home-assistant = {
        enable = true;
        openFirewall = false;
        inherit (cfg) configDir;
        configWritable = true;

        # extraComponents = [
        #   "met"
        #   "openweathermap"
        #   "radio_browser"
        #   "sonarr"
        #   "radarr"
        #   "glances"
        #   "lifx"
        # ];
        # customComponents = [ ];

        config = {
          homeassistant = {
            name = "Home";
            country = "US";
            currency = "USD";
            latitude = "$(cat ${config.sops.secrets."home-assistant/latitude".path})";
            longitude = "$(cat ${config.sops.secrets."home-assistant/longitude".path})";
            elevation = "$(cat ${config.sops.secrets."home-assistant/elevation".path})";
            unit_system = "us_customary";
            temperature_unit = "F";
            time_zone = "US/Eastern";
          };
          # frontend = {
          #   themes = "";
          # };
          http = {
            server_host = [ "100.100.1.2" ];
            server_port = 8123;
          };
          feedreader.urls = [ "https://nixos.org/blogs.xml" ];
        };
        #   customLovelaceModules = [ ];
        #   lovelaceConfigWritable = false;
        #   lovelaceConfig = {
        #     title = "Home";
        #     views = [
        #       {
        #         path = "default_view";
        #         title = "Home";
        #         cards = [
        #           {
        #             type = "light";
        #             entity = "";
        #             name = "";
        #           }
        #           {
        #             type = "sensor";
        #             entity = "";
        #             graph = "line";
        #           }
        #           {
        #             type = "weather-forecast";
        #             entity = "weather.home";
        #             show_forecast = true;
        #           }
        #         ];
        #       }
        #     ];
        #   };
      };

      sops.secrets = {
        "home-assistant/latitude".owner = "hass";
        "home-assistant/longitude".owner = "hass";
        "home-assistant/elevation".owner = "hass";
      };
    })

    {
      services.home-assistant.systemd.services."home-assistant" = lib.mkMerge [
        config.services.home-assistant.systemd.services."home-assistant"
        {
          preStart = ''
            ${config.services.home-assistant.systemd.services."home-assistant".preStart}

            # Process the additional commands for handling secrets at runtime
            envsubst < /etc/home-assistant/configuration.yaml > /etc/home-assistant/configuration.final.yaml
            mv /etc/home-assistant/configuration.final.yaml /etc/home-assistant/configuration.yaml
          '';
        }
      ];
    }
  ];
}
