---
name: odoo
description: Access Odoo ERP at 100.100.1.2:8069 using OdooRPC Python library
---

# Odoo Database Access with OdooRPC

Use OdooRPC to interact with Odoo at `100.100.1.2:8069`.

## Authentication

Use the `ODOO_API_KEY` environment variable (injected automatically):
```python
import os, odoorpc
odoo = odoorpc.ODOO('100.100.1.2', port=8069)
odoo.login('odoo', 'claude@localhost', os.environ['ODOO_API_KEY'])
```

## Execution

Run Python with OdooRPC:
```bash
nix run /home/dtgagnon/nix-config/nixos#odoorpc -- -c "CODE"
```

Example - list databases:
```bash
nix run /home/dtgagnon/nix-config/nixos#odoorpc -- -c "import odoorpc; odoo = odoorpc.ODOO('100.100.1.2', port=8069); print(odoo.db.list())"
```

Example - authenticated query:
```bash
nix run /home/dtgagnon/nix-config/nixos#odoorpc -- -c "
import os, odoorpc
odoo = odoorpc.ODOO('100.100.1.2', port=8069)
odoo.login('odoo', 'claude@localhost', os.environ['ODOO_API_KEY'])
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

## Important Rules

### Task Assignment
**NEVER assign tasks to Claude Bot (user ID 7, login `claude@localhost`).** All tasks must be assigned to **Derek Gagnon (user ID 2, login `gagnon.derek@pm.me`)**.

When creating or updating tasks in `project.task`, always use:
```python
derek_id = 2  # Derek Gagnon
Task.create({'name': 'Task name', 'user_ids': [(6, 0, [derek_id])], ...})
```

### Disabling Mail Notifications for Bulk Operations
When doing bulk updates that would trigger emails, use context to disable notifications:
```python
context = {
    'mail_create_nosubscribe': True,
    'mail_notrack': True,
    'tracking_disable': True,
    'mail_auto_subscribe_no_notify': True,
}
odoo.execute_kw('project.task', 'write', [[task_id], values], {'context': context})
```
