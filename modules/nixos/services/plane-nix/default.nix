{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.spirenix.services.plane-nix;
in
{
  options.spirenix.services.plane-nix = {
    enable = mkBoolOpt false "Enable the Plane project management software service";
  };

  config = mkIf cfg.enable {
    # services.plane = {
    #   enable = true;
    #   domain = "example.com";

    #   # A file containing the secret key used by the Plane api server
    #   secretKeyFile = "";

    #   database = {
    #     local = true;
    #     passwordFile = ""; # File containing the postgres password used by Plane.
    #   };

    #   storage = {
    #     local = true;
    #     credentialsFile = ""; # File containing the minio-style credentials used by Plane. See services.minio.rootCredentialsFile for formatting.
    #   };

    #   cache = {
    #     local = true;
    #   };

    #   acme = {
    #     enable = true;
    #   };
    # };
  };
}
