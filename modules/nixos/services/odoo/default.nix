{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.odoo;
in
{
  options.${namespace}.services.odoo = {
    enable = mkBoolOpt false "Enable Odoo via upstream nixpkgs module";
    db = {
      enableLocalPostgres = mkBoolOpt true "Enable simple local PostgreSQL provisioning";
    };
  };

  config = mkIf cfg.enable {

    sops.secrets.odoo."adminPass" = { };

    # Delegate the service to nixpkgs upstream module.
    services.odoo = {
      enable = true;
      autoInitExtraFlags = [ ];
      addons = [ ];

      # Settings part of application INI file
      settings = {
        options = {
          # admin_passwd = "";

          # Database config
          db_host = "100.100.1.2";
          db_port = "8069";
          db_name = "odoo";
          db_user = "odoo";
        };
      };
    };

    # Optional local PostgreSQL provisioning.
    services.postgresql = mkIf cfg.db.enableLocalPostgres {
      enable = true;
      ensureDatabases = [ "odoo" ];
      ensureUsers = [
        {
          name = "odoo";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };
  };
}
