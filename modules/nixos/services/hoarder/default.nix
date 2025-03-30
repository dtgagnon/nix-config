{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.hoarder;
in
{
  options.${namespace}.services.hoarder = {
    enable = mkBoolOpt false "Enable hoarder, a bookmarks manager";
    configDir = mkOpt types.str "/etc/hoarder" "Declare the directory to store the service configuration";
    dataDir = mkOpt types.str "/srv/hoarder" "Declare the directory to store the service data";
    enableHeadlessBrowser = mkBoolOpt true "Enable headless browser (chromium) for screenshots/archiving";
    group = mkOpt types.str "hoarder" "Declare the group that the service will belong to";
    port = mkOpt types.port 3000 "Default web service port";
    listenAddress = mkOpt types.str "100.100.1.2" "Declare the directory to store the service data";
    user = mkOpt types.str "hoarder" "Declare the user that the service will belong to";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.hoarder ];
    spirenix.services.meilisearch.enable = true;

    systemd = {
      tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.configDir} 0750 ${cfg.user} ${cfg.group} -"
        "L+ '${cfg.configDir}/hoarder.env' - - - - ${config.sops.templates."hoarder.env".path}"
      ];
      targets.hoarder = {
        description = "Hoarder bookmarking service target - groups Hoarder services";
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        wants = [ "hoarder-web.service" "hoarder-workers.service" ] ++ (lib.optional cfg.enableHeadlessBrowser "hoarder-browser.service");
      };
      services = {
        hoarder-migrate = {
          description = "Hoarder database migrations";
          after = [ "local-fs.target" ];
          partOf = [ "hoarder.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = "${pkgs.hoarder}/lib/hoarder/migrate";
            WorkingDirectory = cfg.dataDir;
            EnvironmentFile = "${cfg.configDir}/hoarder.env";
          };
        };
        hoarder-web = {
          description = "Hoarder webGUI";
          requires = [ "hoarder-migrate.service" ];
          after = [ "hoarder-migrate.service" ];
          partOf = [ "hoarder.target" ];
          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = "${pkgs.hoarder}/lib/hoarder/start-web";
            WorkingDirectory = cfg.dataDir;
            EnvironmentFile = "${cfg.configDir}/hoarder.env";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
        hoarder-workers = {
          description = "Hoarder workers service";
          requires = [ "hoarder-migrate.service" ];
          after = [ "hoarder-migrate.service" ];
          wants = lib.optional cfg.enableHeadlessBrowser "hoarder-browser.service";
          partOf = [ "hoarder.target" ];
          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = "${pkgs.hoarder}/lib/hoarder/start-workers";
            WorkingDirectory = cfg.dataDir;
            EnvironmentFile = "${cfg.configDir}/hoarder.env";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
        hoarder-browser = mkIf cfg.enableHeadlessBrowser {
          description = "Hoarder headless browser for crawlers service component";
          after = [ "hoarder-workers.service" ];
          partOf = [ "hoarder.target" ];
          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = ''${pkgs.chromium}/bin/chromium \
							--headless \
							--no-sandbox \
							--remote-debugging-port=9222 \
							--disable-gpu \
							--user-data-dir=${cfg.dataDir}/chrome-profile
						'';
            WorkingDirectory = cfg.dataDir;
            Restart = "on-failure";
            RestartSec = 10;
            # Add resource limits if needed
            # MemoryMax = "";
            # CPUQuota = "";
          };
        };
      };
    };

    users = {
      users.${cfg.user} = {
        group = cfg.group;
        isSystemUser = true;
        home = cfg.dataDir;
      };
      groups."${cfg.group}" = { };
    };

    sops = {
      secrets = {
        "hoarder/nextauth-seed" = { };
        "hoarder/meili-masterkey" = { };
        openai-api-key = { };
      };
      templates = {
        "hoarder.env" = {
          owner = "${cfg.user}";
          group = "${cfg.group}";
          content = ''
            API_URL=http://${cfg.listenAddress}:${toString cfg.port}
            HOARDER_SERVER_ADDR=http://${cfg.listenAddress}:${toString cfg.port}
            HOARDER_API_KEY=
            DATA_DIR=${cfg.dataDir}

            NEXTAUTH_URL=http://localhost:${toString cfg.port}
            NEXTAUTH_SECRET=${config.sops.placeholder."hoarder/nextauth-seed"}

            MEILI_ADDR=http://${config.services.meilisearch.listenAddress}:${toString config.services.meilisearch.listenPort}
            MEILI_MASTER_KEY=${config.sops.placeholder."hoarder/meili-masterkey"}

            # ai config
            OPENAI_API_KEY=${config.sops.placeholder.openai-api-key}
            INFERENCE_TEXT_MODEL=gpt-4o-mini
            INFERENCE_IMAGE_MODEL=gpt-4o-mini
            EMBEDDING_TEXT_MODEL=text-embedding-3-small
            INFERENCE_CONTEXT_LENGTH=2048
            INFERENCE_LANG=english
            INFERENCE_JOB_TIMEOUT_SEC=30
            # INFERENCE_FETCH_TIMEOUT_SEC=300 # For ollama only
            INFERENCE_SUPPORTS_STRUCTURED_OUTPUT=true

            # Headless browser config
            ${lib.optionalString cfg.enableHeadlessBrowser ''
            BROWSER_WEB_URL=http://127.0.0.1:9222
            ''}

            # Crawler configs
            # CRAWLER_NUM_WORKERS=2
            # CRAWLER_STORE_SCREENSHOT=true # Default
            # CRAWLER_FULL_PAGE_ARCHIVE=false # Default
            # CRAWLER_VIDEO_DOWNLOAD=false # Default

            #MISC
            DISABLE_NEW_RELEASE_CHECK=true
          '';
        };
      };
    };
  };
}
