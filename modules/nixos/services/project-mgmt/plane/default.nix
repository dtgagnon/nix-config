{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.project-mgmt.plane;
in
{
  options.${namespace}.services.project-mgmt.plane = {
    enable = mkBoolOpt false "Enable Plane project management platform service";
  };

  config = mkIf cfg.enable {
    services.plane = {
      enable = true;
      package = pkgs.plane-nix.plane;
      domain = "100.100.0.0";
      user = "plane";
      group = "plane";
      stateDir = "/var/lib/plane";
      secretKeyFile = null;

      web.port = 3101;
      admin.port = 3102;

      api = {
        workers = 1;
        port = 3103;
      };

      space.port = 3104;

      database = {
        local = true;
        user = "plane";
        passwordFile = null;
        name = "plane";
        host = "localhost";
        port = 5432;
      };

      storage = {
        local = true;
        region = "us-east-1";
        credentialsFile = null;
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

      acme.enable = false;
    };
  };
}
