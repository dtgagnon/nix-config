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

      defaultIntegrations = [
        "application_credentials"
        "frontend"
        "hardware"
        "logger"
        "network"
        "system_health"
        "automation"
        "person"
        "scene"
        "script"
        "tag"
        "zone"
        "counter"
        "input_boolean"
        "input_button"
        "input_datetime"
        "input_number"
        "input_select"
        "input_text"
        "schedule"
        "timer"
        "backup"
      ];

      extraPackages = python3Packages: with python3Packages; [
        # Packages to add to propagatedBuildInputs
        # postgresql support
        ## psycopg2 for example
      ];

      extraComponents = [ ];
      customComponents = [ ];

      inherit (cfg) configDir;
      configWritable = false;
      config = {
        homeassistant = {
          name = "Home";
          latitude = ""; # it's a good idea to have location information encrypted and managed with sops
          longitude = "";
          elevation = "";
          unit_system = "";
          time_zone = "";
        };
        frontend = {
          themes = "";
        };
        http = { };
        feedreader.urls = [ "https://nixos.org/blogs.xml" ];
      };

      customLovelaceModules = [ ];
      lovelaceConfigWritable = false;
      lovelaceConfig = { };
    };
  };
}
