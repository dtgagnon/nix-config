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
    # Delegate the service to nixpkgs upstream module.
    services.odoo = {
      enable = true;
      autoInitExtraFlags = [ ];
      addons = [ ];

      # Settings part of application INI file
      settings = {
        options = {
          db_user = "odoo";
          db_password = "odoo";
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
