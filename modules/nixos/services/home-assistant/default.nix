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
    energy = {
      peakRateWinter = mkOpt types.str "0.1912" "The peak energy rate in winter";
      offPeakRateWinter = mkOpt types.str "0.1764" "The off-peak energy rate in winter";
      peakRateSummer = mkOpt types.str "0.2339" "The peak energy rate in summer";
      offPeakRateSummer = mkOpt types.str "0.1764" "The off-peak energy rate in summer";
    };
  };

  config = mkIf cfg.enable {
    # AI/LLM Integration:
    # - When Ollama is enabled: Uses native "ollama" integration
    # - When llama-cpp is enabled: Uses "openai" integration with custom endpoint
    #   Configure in Home Assistant UI: Settings -> Integrations -> Add OpenAI Conversation
    #   Set API endpoint to: http://100.100.2.1:11434/v1
    #   API key can be anything (llama-cpp doesn't require auth by default)

    # Creates automations.yaml file so that Hass doesn't fail to load when splitting into declarative and ui configured automations.
    systemd.tmpfiles.rules = [ "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass" ];
    services.home-assistant = {
      enable = true;
      openFirewall = false;
      inherit (cfg) configDir;
      configWritable = true;

      config = {
        "automation declarations" = [
          { }
        ];
        "automation ui" = "!include automations.yaml";
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
        http = {
          server_host = [ "100.100.1.2" ];
          server_port = 8123;
        };
        recorder.db_url = "postgresql://@/hass";
        template = {
          sensor = {
            name = "D1.11 Inflow";
            unit_of_measurement = "USD/kWh";
            device_class = "monetary";
            state = ''
              {# Current rates found through the Michigan Public Service Commission's website,
                 https://www.michigan.gov/mpsc . These rates include:
                 * capacity charge
                 * non-capacity charge
                 * delivery charge
                 * Power Supply Cost Recovery (PSCR) charge of 0.25 cents/kWh, which has been static since November 2024 but is subject to change
              #}
              {% set month = now().month %}
              {% set day_of_week = now().isoweekday() %}
              {% set hour = now().hour %}
              {% if hour < 15 or hour >= 19 or day_of_week in [6, 7] %}
                ${cfg.energy.offPeakRateWinter}
              {% else %}
              {% if month in [10, 11, 12, 1, 2, 3, 4, 5] %}
                ${cfg.energy.peakRateWinter}
              {% elif month in [6, 7, 8, 9] %}
                ${cfg.energy.peakRateSummer}
              {% endif %}
              {% endif %}
            '';
          };
        };
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
        "esphome"
        "glances"
        "google"
        "google_maps"
        "homekit"
        "homekit_controller"
        "ibeacon"
        "jellyfin"
        "lifx"
        "matter"
        "mobile_app"
        "monarch_money"
        "nest"
        "opensensemap"
        "openweathermap"
        "qbittorrent"
        "radarr"
        "reddit"
        "sabnzbd"
        "samsungtv"
        "sonarr"
        "tailscale"
        "tplink"
      ] ++ lib.optional config.services.ollama.enable "ollama"
        ++ lib.optional config.${namespace}.services.llama-cpp.enable "openai";

      customComponents = with pkgs.home-assistant-custom-components; [
        midea_ac_lan
        nest_protect
        sleep_as_android_mqtt
        waste_collection_schedule
      ];

      extraPackages = python3Packages: with python3Packages; [
        psycopg2
        python-otbr-api
        getmac
        aiohomekit
        grpcio
        ical #local_todo
        pyatv #apple_tv
        pysabnzbd #sabnzbd
        qbittorrent-api #qbittorrent
        gcal-sync #google
        oauth2client #google
        locationsharinglib #google_maps
        typedmonarchmoney #monarch_money
        python-kasa #kasa devices
        kegtron-ble #ibeacon
        samsungtvws #samsung TV (WebSocket)

        # # HomeKit
        # base36
        # fnv-hash-fast
        # ha-ffmpeg
        # hap-python
        # ifaddr
        # pyqrcode
        # pyturbojpeg
        # zeroconf
        #
        # # HomeKit Controller
        # aioesphomeapi
        # aiohasupervisor
        # aiohomekit
        # aioruuvigateway
        # aioshelly
        # aiousbwatcher
        # bleak
        # bleak-esphome
        # bleak-retry-connector
        # bluetooth-adapters
        # bluetooth-auto-recovery
        # bluetooth-data-tools
        # dbus-fast
        # esphome-dashboard-api
        # ha-ffmpeg
        # habluetooth
        # hassil
        # home-assistant-intents
        # ifaddr
        # mutagen
        # pymicro-vad
        # pyroute2
        # pyserial
        # pyspeex-noise
        # python-otbr-api
        # zeroconf
        #
        # # ESPhome
        # aioblescan
        # aioesphomeapi
        # aiohasupervisor
        # aiousbwatcher
        # bleak
        # bleak-esphome
        # bleak-retry-connector
        # bluetooth-adapters
        # bluetooth-auto-recovery
        # bluetooth-data-tools
        # dbus-fast
        # esphome-dashboard-api
        # govee-ble
        # ha-ffmpeg
        # habluetooth
        # hassil
        # home-assistant-intents
        # ibeacon-ble
        # ifaddr
        # kegtron-ble
        # mutagen
        # pymicro-vad
        # pyserial
        # pyspeex-noise
        # zeroconf
      ];
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

    # go2rtc camera streaming service for IOT cameras (EC70, KC100, etc.)
    services.go2rtc = {
      enable = true;
      settings = {
        streams = {
          kasaCam = "\${KASA_CAM_FEED}";
        };
      };
    };

    # Load the kasaCamFeed secret as an environment variable
    systemd.services.go2rtc = {
      serviceConfig = {
        EnvironmentFile = config.sops.secrets.kasaCamFeed.path;
      };
    };

    sops.secrets = {
      "hass/latitude".owner = "hass";
      "hass/longitude".owner = "hass";
      "hass/elevation".owner = "hass";
      kasaCamFeed = { };
    };
  };
}
