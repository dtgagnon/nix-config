{ lib
, config
, inputs
, namespace
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.odoo;
  ocaAddons = inputs.odooAdds.ocaAddons;
in
{
  options.${namespace}.services.odoo = {
    enable = mkBoolOpt false "Enable Odoo via upstream nixpkgs module";
    db = {
      enableLocalPostgres = mkBoolOpt true "Enable simple local PostgreSQL provisioning";
    };
    mcp = {
      enable = mkBoolOpt false "Enable Odoo MCP server";
    };
  };

  config = mkIf cfg.enable {
    # Declare the secret using native sops-nix.
    sops.secrets."odoo/adminPass" = {
      owner = "odoo";
      group = "odoo";
      mode = "0400";
      restartUnits = [ "odoo.service" ];
    };

    # Delegate the service to nixpkgs upstream module.
    services.odoo = {
      enable = true;
      autoInit = true;
      autoInitExtraFlags = [
        "--load-language=en_US"
        "--without-demo=all"
      ];
      addons = [
        ocaAddons.account-analytic
        ocaAddons.account-financial-reporting
        ocaAddons.account-financial-tools
        ocaAddons.account-invoicing
        ocaAddons.account-invoice-reporting
        ocaAddons.account-payment
        # ocaAddons.account-reconcile
        ocaAddons.ai
        ocaAddons.bank-payment
        ocaAddons.connector
        ocaAddons.contract
        ocaAddons.crm
        ocaAddons.dms
        ocaAddons.hr
        ocaAddons.knowledge
        ocaAddons.management-system
        ocaAddons.manufacture
        ocaAddons.mis-builder
        ocaAddons.partner-contact
        ocaAddons.product-attribute
        ocaAddons.project
        ocaAddons.queue
        ocaAddons.reporting-engine
        ocaAddons.rest-framework
        ocaAddons.sale-workflow
        ocaAddons.server-auth
        ocaAddons.server-tools
        ocaAddons.server-ux
        ocaAddons.stock-logistics-shopfloor
        ocaAddons.stock-logistics-tracking
        ocaAddons.stock-logistics-transport
        ocaAddons.stock-logistics-warehouse
        ocaAddons.timesheet
        ocaAddons.web
        ocaAddons.web-api
      ];

      # Settings part of application INI file
      settings = {
        options = {
          admin_passwd = "temp";
          server_wide_modules = "base,web,web_enterprise";
          limit_time_real = 3600;
          limit_time_cpu = 3600;

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

    systemd.services.odoo.serviceConfig.TimeoutStartSec = 300;

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

    systemd.services.odoo-mcp = mkIf cfg.mcp.enable {
      description = "Odoo MCP Server";
      after = [ "odoo.service" ];
      partOf = [ "odoo.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "odoo";
        Group = "odoo";
        ExecStart = "${lib.getExe pkgs.odoo-mcp}";
        Restart = "always";
        RestartSec = "10s";
      };
    };
  };
}
