{ lib
, pkgs
, config
, inputs
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.plane;
in
{
  options.${namespace}.services.plane = {
    enable = mkBoolOpt false "Enable Plane project management platform service";
  };

  config = mkIf cfg.enable {
    services.plane = {
      enable = true;
      package = inputs.plane.packages.${pkgs.system}.plane;
      domain = "100.100.0.0";
      user = "plane";
      group = "plane";
      stateDir = "/var/lib/plane";
      secretKeyFile = config.sops.secrets."plane/apiKey".path;

      web = {
        enable = true;
        port = 3101;
      };

      admin = {
        enable = true;
        port = 3102;
      };

      api = {
        enable = true;
        workers = 1;
        port = 3103;
      };

      space = {
        enable = true;
        port = 3104;
      };

      live = {
        enable = false;
        port = 3105;
      };

      worker = {
        enable = true;
      };

      beat = {
        enable = true;
      };

      database = {
        local = true;
        user = "plane";
        passwordFile = config.sops.secrets."plane/dbPass".path;
        name = "plane";
        host = "localhost";
        port = 5432;
      };

      storage = {
        local = true;
        region = "us-east-1";
        credentialsFile = config.sops.secrets."plane/strCreds".path;
        host = "127.0.0.1";
        port = 9000;
        bucket = "uploads";
        protocol = "http";
      };

      cache = {
        local = true;
        host = "127.0.0.1";
        port = 6379;
      };

      rabbitmq = {
        local = true;
        host = "127.0.0.1";
        port = 5672;
        user = "plane";
        passwordFile = config.sops.secrets."plane/rabbitmqPass".path;
        vhost = "plane";
      };

      nginx = {
        enable = true;
      };

      acme = {
        enable = false;
      };
    };

    sops.secrets = {
      "plane/apiKey" = { };
      "plane/dbPass" = { };
      "plane/strCreds" = { };
      "plane/rabbitmqPass" = { };
    };
  };
}
