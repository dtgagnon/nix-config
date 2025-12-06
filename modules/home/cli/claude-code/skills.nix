{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.cli.claude-code;
in
{
  config = mkIf cfg.enable {
    # Claude Code skills are stored in ~/.claude/skills/<skill-name>/SKILL.md
    home.file.".claude/skills/odoo/SKILL.md".text = ''
      ---
      name: odoo
      description: Access and administer Odoo ERP database at 100.100.2.1:8069 via JSON-RPC
      ---

      # Odoo Database Administration

      You have access to an Odoo ERP system via the `odoo` MCP server. The server connects to `http://100.100.2.1:8069`.

      ## Available Tools

      - **login** - Authenticate with the Odoo database (required before other operations)
        - `db`: Database name
        - `user`: Username  
        - `password`: Password

      - **search_read** - Search and read records from any model
        - `model`: Model name (e.g., "res.partner", "sale.order")
        - `domain`: Search domain filter (e.g., `[["is_company", "=", true]]`)
        - `fields`: Optional list of fields to return
        - `limit`: Optional max records to return

      - **write** - Update existing records
        - `model`: Model name
        - `ids`: List of record IDs to update
        - `vals`: Object with field values to update

      - **execute** - Execute any method on a model
        - `model`: Model name
        - `method`: Method name
        - `args`: Positional arguments
        - `kwargs`: Keyword arguments

      - **inspect_model** - Get field definitions for a model
        - `model`: Model name

      ## Workflow

      1. Always **login** first before performing any other operations
      2. Use **inspect_model** to discover available fields on a model
      3. Use **search_read** to query data
      4. Use **write** or **execute** to modify data

      ## Common Odoo Models

      - `res.partner` - Contacts/customers
      - `res.users` - System users
      - `sale.order` - Sales orders
      - `purchase.order` - Purchase orders
      - `account.move` - Invoices/journal entries
      - `product.product` - Products
      - `stock.picking` - Inventory transfers
      - `project.project` - Projects
      - `project.task` - Tasks

      ## Example Queries

      ```
      # Login first
      login(db="mydb", user="admin", password="admin")

      # Get all companies
      search_read(model="res.partner", domain=[["is_company", "=", true]], fields=["name", "email"])

      # Inspect a model's fields
      inspect_model(model="sale.order")
      ```
    '';
  };
}
