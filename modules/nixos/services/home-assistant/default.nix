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
      openFirewall = false;
      inherit (cfg) configDir;
      configWritable = true;

      config = {
        default_config = { };
        homeassistant = {
          name = "Home";
          country = "US";
          currency = "USD";
          latitude = "\${LATITUDE}";
          longitude = "\${LONGITUDE}";
          elevation = "\${ELEVATION}";
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
        recorder.db_url = "postgresql://@/hass";
      };
      #   customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      #     advanced-camera-card
      #     bubble-card
      #     clock-weather-card
      #     mini-graph-card
      #     mini-media-player
      #     versatile-thermostat-ui-card
      #     weather-chart-card
      #   ];
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

      extraComponents = [
        # Components required to complete onboarding
        "analytics"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"
        "isal" # Recommended for fast zlib compression

        # Other
        "androidtv_remote"
        "asuswrt"
        "bluetooth"
        "bluetooth_adapters"
        "calendar"
        "cast"
        "default_config"
        "emulated_kasa"
        "glances"
        "homekit"
        "homekit_controller"
        "jellyfin"
        "lifx"
        "matter"
        "mobile_app"
        "monarch_money"
        "nest"
        "ollama"
        "opensensemap"
        "openweathermap"
        "radarr"
        "reddit"
        "samsungtv"
        "sonarr"
        "tailscale"
        "tplink"
      ];

      customComponents = with pkgs.home-assistant-custom-components; [
        midea_ac_lan
        nest_protect
        sleep_as_android
        waste_collection_schedule
      ];

      extraPackages = python3Packages: with python3Packages; [
        psycopg2
        python-otbr-api
        getmac
        aiohomekit
        grpcio
      ];
    };



    sops.secrets = {
      "hass/latitude".owner = "hass";
      "hass/longitude".owner = "hass";
      "hass/elevation".owner = "hass";
    };

    # Process the additional commands for handling secrets at runtime
    systemd.services."home-assistant" = {
      path = [ pkgs.coreutils pkgs.gettext ];
      preStart = lib.mkAfter ''
        # Export variables for envsubst, reading from sops secrets files
        export LATITUDE=$(cat "${config.sops.secrets."hass/latitude".path}")
        export LONGITUDE=$(cat "${config.sops.secrets."hass/longitude".path}")
        export ELEVATION=$(cat "${config.sops.secrets."hass/elevation".path}")

        # Define the correct configuration file path and a temp file
        CONF_FILE="${cfg.configDir}/configuration.yaml"
        TEMP_CONF_FILE="$CONF_FILE.tmp"

        # Basic check if secrets were read
        if [ -z "$LATITUDE" ] || [ -z "$LONGITUDE" ] || [ -z "$ELEVATION" ]; then
        echo "Error: One or more secret values could not be read." >&2
        exit 1
        fi

        echo "Attempting substitution into $CONF_FILE"
        # Perform the substitution using envsubst
        envsubst < "$CONF_FILE" > "$TEMP_CONF_FILE"

        if [ $? -eq 0 ]; then
        # Replace original file, set ownership/permissions
        mv "$TEMP_CONF_FILE" "$CONF_FILE"
        echo "Secrets successfully substituted into $CONF_FILE."
        else
        echo "Error during envsubst execution. Configuration not updated." >&2
        rm -f "$TEMP_CONF_FILE"
        exit 1 # Fail the service start
        fi
      '';
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "hass" ];
      ensureUsers = [{
        name = "hass";
        ensureDBOwnership = true;
      }];
    };
  };
}
