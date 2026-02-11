{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkForce types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.karakeep;
in
{
  options.${namespace}.services.karakeep = {
    enable = mkBoolOpt false "Enable karakeep, a bookmarks manager";
    port = mkOpt types.port 3000 "Default web service port";
    listenAddress = mkOpt types.str "100.100.1.2" "Listen address for the service";
    dataDir =
      mkOpt types.str "/srv/karakeep"
        "Directory to store service data (bookmarks, screenshots, archives, videos)";
  };

  config = mkIf cfg.enable {
    # Enable official karakeep module
    services.karakeep = {
      enable = true;
      browser.enable = true;
      meilisearch.enable = false; # We configure meilisearch separately

      # Point to sops-managed secrets
      environmentFile = config.sops.templates."karakeep-secrets.env".path;

      extraEnvironment = {
        # Meilisearch connection
        MEILI_ADDR = "http://${config.services.meilisearch.listenAddress}:${toString config.services.meilisearch.listenPort}";

        # Network configuration
        API_URL = "http://${cfg.listenAddress}:${toString cfg.port}";
        KARAKEEP_SERVER_ADDR = "http://${cfg.listenAddress}:${toString cfg.port}";
        NEXTAUTH_URL = "http://localhost:${toString cfg.port}";

        # AI configuration
        INFERENCE_TEXT_MODEL = "gpt-5-nano";
        INFERENCE_IMAGE_MODEL = "gpt-5-nano";
        EMBEDDING_TEXT_MODEL = "text-embedding-3-small";
        INFERENCE_CONTEXT_LENGTH = "2048";
        INFERENCE_LANG = "english";
        INFERENCE_JOB_TIMEOUT_SEC = "30";
        INFERENCE_SUPPORTS_STRUCTURED_OUTPUT = "true";

        # Misc
        DISABLE_NEW_RELEASE_CHECK = "true";
      };
    };

    systemd.services.karakeep-web.environment.DATA_DIR = mkForce cfg.dataDir;
    systemd.services.karakeep-workers.environment.DATA_DIR = mkForce cfg.dataDir;

    # Override karakeep-init to migrate the custom data directory.
    # The upstream NixOS module's init script hardcodes DATA_DIR=$STATE_DIRECTORY,
    # which runs migrations against /var/lib/karakeep instead of cfg.dataDir.
    systemd.services.karakeep-init.serviceConfig.ExecStart =
      let
        karakeep = config.services.karakeep.package;
      in
      mkForce (
        toString (
          pkgs.writeShellScript "karakeep-init-start" ''
                    set -e
                    umask 0077

                    if [ ! -f "$STATE_DIRECTORY/settings.env" ]; then
                      cat <<EOF >"$STATE_DIRECTORY/settings.env"
            MEILI_MASTER_KEY=$(${pkgs.openssl}/bin/openssl rand -base64 36)
            NEXTAUTH_SECRET=$(${pkgs.openssl}/bin/openssl rand -base64 36)
            EOF
                    fi

                    export DATA_DIR="${cfg.dataDir}"
                    exec "${karakeep}/lib/karakeep/migrate"
          ''
        )
      );

    # Configure sops secrets for karakeep
    sops = {
      secrets = {
        "karakeep/meili-masterkey" = { };
        openai-api-key = { };
      };

      templates."karakeep-secrets.env" = {
        owner = "karakeep";
        group = "karakeep";
        content = ''
          OPENAI_API_KEY=${config.sops.placeholder.openai-api-key}
          MEILI_MASTER_KEY=${config.sops.placeholder."karakeep/meili-masterkey"}
        '';
      };

    };

    # Configure meilisearch with the shared master key
    services.meilisearch = {
      enable = true;
      listenAddress = "127.0.0.1";
      listenPort = 7700;
      masterKeyFile = config.sops.secrets."karakeep/meili-masterkey".path;
    };

    # Ensure data directory exists (official module only creates /var/lib/karakeep)
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 karakeep karakeep -"
    ];
  };
}
