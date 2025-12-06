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
      description: Access Odoo ERP at 100.100.2.1:8069 using OdooRPC Python library
      ---

      # Odoo Database Access with OdooRPC

      Use OdooRPC to interact with Odoo at `100.100.2.1:8069`.

      ## Execution

      Run Python with OdooRPC using:
      ```bash
      nix run /home/dtgagnon/nix-config/nixos#odoorpc -- -c "CODE"
      ```

      Example one-liner:
      ```bash
      nix run /home/dtgagnon/nix-config/nixos#odoorpc -- -c "import odoorpc; odoo = odoorpc.ODOO('100.100.2.1', port=8069); print(odoo.db.list())"
      ```

      Multi-line example:
      ```bash
      nix run /home/dtgagnon/nix-config/nixos#odoorpc -- -c "
      import odoorpc
      odoo = odoorpc.ODOO('100.100.2.1', port=8069)
      odoo.login('DATABASE', 'USER', 'PASSWORD')
      print(odoo.env.user.name)
      "
      ```

      ## Core Operations

      ### Browse Records
      ```python
      Partner = odoo.env['res.partner']
      partner = Partner.browse(1)
      print(partner.name)
      ```

      ### Search and Read
      ```python
      # Search returns IDs
      ids = Partner.search([('is_company', '=', True)], limit=10)

      # Read returns field values
      data = Partner.read(ids, ['name', 'email'])

      # Combined search_read
      records = Partner.search_read([('is_company', '=', True)], ['name', 'email'], limit=10)
      ```

      ### Create Records
      ```python
      new_id = Partner.create({'name': 'New Partner', 'email': 'new@example.com'})
      ```

      ### Update Records
      ```python
      Partner.write([partner_id], {'name': 'Updated Name'})
      # Or via browse
      partner.name = 'Updated Name'
      ```

      ### Delete Records
      ```python
      Partner.unlink([partner_id])
      ```

      ### Execute Methods
      ```python
      result = Partner.execute('method_name', arg1, arg2, kwarg=value)
      ```

      ## Common Models

      | Model | Purpose |
      |-------|---------|
      | res.partner | Contacts/customers |
      | res.users | System users |
      | sale.order | Sales orders |
      | purchase.order | Purchase orders |
      | account.move | Invoices/journals |
      | product.product | Products |
      | stock.picking | Inventory transfers |
      | project.task | Tasks |

      ## Domain Filter Syntax

      ```python
      # Operators: =, !=, >, <, >=, <=, like, ilike, in, not in
      [('field', 'operator', value)]

      # AND (default)
      [('is_company', '=', True), ('country_id.code', '=', 'US')]

      # OR
      ['|', ('name', 'ilike', 'test'), ('email', 'ilike', 'test')]
      ```

      ## Inspect Model Fields

      ```python
      fields = odoo.env['res.partner'].fields_get()
      ```
    '';
  };
}
