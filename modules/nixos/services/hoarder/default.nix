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
    user = mkOpt types.str "hoarder" "Declare the user that the service will belong to";
    group = mkOpt types.str "hoarder" "Declare the group that the service will belong to";
    configDir = mkOpt types.str "/etc/hoarder" "Declare the directory to store the service data";
    dataDir = mkOpt types.str "/var/lib/hoarder" "Declare the directory to store the service data";
    serverAddress = mkOpt types.str "100.100.1.2" "Declare the directory to store the service data";
    port = mkOpt types.str "9222" "Declare the directory to store the service data";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.hoarder ];

    systemd = {
      tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.configDir} 0750 ${cfg.user} ${cfg.group} -"
        "C '${cfg.configDir}/hoarder.env' 0600 ${cfg.user} ${cfg.group} - ${config.sops.templates."hoarder.env".path}"
      ];
      targets.hoarder = {
        description = "Hoarder bookmarking service target - groups Hoarder services";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        wants = [ "hoarder-web.service" "hoarder-workers.service" ];
      };
      services = {
        hoarder-web = {
          description = "Hoarder webGUI";
          after = [ "hoarder.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            PartOf = "hoarder.target";
            Type = "simple";
            User = "${cfg.user}";
            ExecStart = "${pkgs.hoarder}/lib/hoarder/start-web";
            WorkingDirectory = "${cfg.dataDir}";
            Restart = "on-failure";
          };
        };
        hoarder-workers = {
          description = "Hoarder workers service";
          after = [ "hoarder.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            PartOf = "hoarder.target";
            Type = "simple";
            User = "${cfg.user}";
            ExecStart = "${pkgs.hoarder}/lib/hoarder/start-workers";
            WorkingDirectory = "${cfg.dataDir}";
            Restart = "on-failure";
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
            HOARDER_SERVER_ADDR=${cfg.serverAddress}:${cfg.port}
            HOARDER_API_KEY=
            DATA_DIR="${cfg.dataDir}"

            NEXTAUTH_URL=http://localhost:3003
            NEXTAUTH_SECRET=${config.sops.placeholder."hoarder/nextauth-seed"}

            # ai config
            MEILI_ADDR=
            MEILI_MASTER_KEY=${config.sops.placeholder."hoarder/meili-masterkey"}
            OPENAI_API_KEY=${config.sops.placeholder.openai-api-key}
            INFERENCE_TEXT_MODEL=gpt-4o-mini
            INFERENCE_IMAGE_MODEL=gpt-4o-mini
            EMBEDDING_TEXT_MODEL=text-embedding-3-small
            INFERENCE_CONTEXT_LENGTH=2048
            INFERENCE_LANG=english
            INFERENCE_JOB_TIMEOUT_SEC=30
            # INFERENCE_FETCH_TIMEOUT_SEC=300 # For ollama only
            INFERENCE_SUPPORTS_STRUCTURED_OUTPUT=true
          '';
        };
      };
    };
  };
}
