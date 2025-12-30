{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.karakeep;

  forBoth = "gpt-5-nano";
  txt-model = "${forBoth}";
  img-model = "${forBoth}";
  embedding-model = "text-embedding-3-small";
in
{
  options.${namespace}.services.karakeep = {
    enable = mkBoolOpt false "Enable karakeep, a bookmarks manager";
    configDir = mkOpt types.str "/etc/karakeep" "Declare the directory to store the service configuration";
    dataDir = mkOpt types.str "/srv/karakeep" "Declare the directory to store the service data";
    enableHeadlessBrowser = mkBoolOpt true "Enable headless browser (chromium) for screenshots/archiving";
    group = mkOpt types.str "karakeep" "Declare the group that the service will belong to";
    port = mkOpt types.port 3000 "Default web service port";
    listenAddress = mkOpt types.str "100.100.1.2" "Declare the directory to store the service data";
    user = mkOpt types.str "karakeep" "Declare the user that the service will belong to";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.karakeep ];
    spirenix.services.meilisearch.enable = true;

    systemd = {
      tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.configDir} 0750 ${cfg.user} ${cfg.group} -"
        "L+ '${cfg.configDir}/karakeep.env' - - - - ${config.sops.templates."karakeep.env".path}"
      ];
      targets.karakeep = {
        description = "karakeep bookmarking service target - groups karakeep services";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" "karakeep-web.service" "karakeep-workers.service" ] ++ (lib.optional cfg.enableHeadlessBrowser "karakeep-browser.service");
        wantedBy = [ "multi-user.target" ];
      };
      services = {
        karakeep-migrate = {
          description = "karakeep database migrations";
          after = [ "local-fs.target" ];
          partOf = [ "karakeep.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = "${pkgs.karakeep}/lib/karakeep/migrate";
            WorkingDirectory = cfg.dataDir;
            EnvironmentFile = "${cfg.configDir}/karakeep.env";
          };
        };
        karakeep-web = {
          description = "karakeep webGUI";
          requires = [ "karakeep-migrate.service" ];
          after = [ "karakeep-migrate.service" ];
          partOf = [ "karakeep.target" ];
          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = "${pkgs.karakeep}/lib/karakeep/start-web";
            WorkingDirectory = cfg.dataDir;
            EnvironmentFile = "${cfg.configDir}/karakeep.env";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
        karakeep-workers = {
          description = "karakeep workers service";
          requires = [ "karakeep-migrate.service" ];
          after = [ "karakeep-migrate.service" ];
          wants = lib.optional cfg.enableHeadlessBrowser "karakeep-browser.service";
          partOf = [ "karakeep.target" ];
          serviceConfig = {
            Type = "simple";
            User = cfg.user;
            Group = cfg.group;
            ExecStart = "${pkgs.karakeep}/lib/karakeep/start-workers";
            WorkingDirectory = cfg.dataDir;
            EnvironmentFile = "${cfg.configDir}/karakeep.env";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
        karakeep-browser = mkIf cfg.enableHeadlessBrowser {
          description = "karakeep headless browser for crawlers service component";
          after = [ "karakeep-workers.service" ];
          partOf = [ "karakeep.target" ];
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
        "karakeep/nextauth-seed" = { };
        "karakeep/meili-masterkey" = { };
        openai-api-key = { };
      };
      templates = {
        "karakeep.env" = {
          owner = "${cfg.user}";
          group = "${cfg.group}";
          content = ''
            API_URL=http://${cfg.listenAddress}:${toString cfg.port}
            karakeep_SERVER_ADDR=http://${cfg.listenAddress}:${toString cfg.port}
            karakeep_API_KEY=
            DATA_DIR=${cfg.dataDir}

            NEXTAUTH_URL=http://localhost:${toString cfg.port}
            NEXTAUTH_SECRET=${config.sops.placeholder."karakeep/nextauth-seed"}

            MEILI_ADDR=http://${config.services.meilisearch.listenAddress}:${toString config.services.meilisearch.listenPort}
            MEILI_MASTER_KEY=${config.sops.placeholder."karakeep/meili-masterkey"}

            # ai config
            OPENAI_API_KEY=${config.sops.placeholder.openai-api-key}
            INFERENCE_TEXT_MODEL=${txt-model}
            INFERENCE_IMAGE_MODEL=${img-model}
            EMBEDDING_TEXT_MODEL=${embedding-model}
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
