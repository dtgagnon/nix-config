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
  cfg = config.${namespace}.services.odoo;
  odooAddons = inputs.odoo-oca-repos.odoo_oca_repos; #TODO: Figure out how to reference these individual repos in this flake
in
{
  options.${namespace}.services.odoo = {
    enable = mkBoolOpt false "Enable Odoo via upstream nixpkgs module";
    db = {
      enableLocalPostgres = mkBoolOpt true "Enable simple local PostgreSQL provisioning";
    };
  };

  config = mkIf cfg.enable {
    spirenix.security.sops-nix.plainTextSecrets."odoo.admin-password" = {
      secret = "odoo/adminPass";
      usedBy = "services.odoo.settings.options.admin_passwd";
      owner = "odoo";
      group = "odoo";
      mode = "0400";
      restartUnits = [ "odoo.service" ];
    };

    # Delegate the service to nixpkgs upstream module.
    services.odoo = {
      enable = true;
      autoInit = true;
      autoInitExtraFlags = [ "--load-language=en_US" "--without-demo=all" ];
      addons = with odooAddons; [
        account-analytic
        account-financial-reporting
        account-financial-tools
        account-invoicing
        account-invoice-reporting
        account-payment
        account-reconcile
        ai
        bank-payment
        connector
        contract
        crm
        dms
        hr
        knowledge
        management-system
        manufacture
        mis-builder
        partner-contact
        project
        queue
        reporting-engine
        rest-framework
        sale-workflow
        server-auth
        server-tools
        server-ux
        timesheet
        web

        project-gantt
      ];

      # Settings part of application INI file
      settings = {
        options = {
          admin_passwd = config.spirenix.security.sops-nix.secretStrings."odoo.admin-password";
          # WebUI
          http_interface = "0.0.0.0";
          http_port = 8069;
          web_base_url = "http://spirepoint.aegean-interval.ts.net";

          # Database config; use UNIX socket so peer auth works without a password.
          db_host = "False";
          db_port = "False";
          db_name = "odoo";
          db_user = "odoo";
          db_password = "False";
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
