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
    '';

    home.file.".claude/skills/obsidian-bases/SKILL.md".text = ''
      ---
      name: obsidian-bases
      description: Create Obsidian database views (Bases) using YAML syntax for note organization and tracking
      ---

      # Obsidian Bases - Database Views for Your Notes

      Create database-like views of your notes in Obsidian. Bases let you view, edit, sort, and filter files using their properties.

      ## Two Ways to Create Bases

      ### Standalone .base File
      For complex, reusable databases. Create a file with `.base` extension:
      ```bash
      # Embed in a note with:
      ![[filename.base]]
      # Or with specific view:
      ![[filename.base#ViewName]]
      ```

      ### Embedded Code Block
      For quick inline databases within notes:
      ````markdown
      ```base
      filters:
        file.hasTag("example")
      views:
        - type: table
          name: Table
      ```
      ````

      ## Minimal Working Example

      ```yaml
      views:
        - type: table
          name: All Files
      ```

      ## Core Syntax Structure

      A base file has 5 main sections (only `views` is required):

      ```yaml
      filters:           # Optional - narrow down files globally
        and/or/not: ...

      formulas:          # Optional - computed properties
        formula_name: "expression"

      properties:        # Optional - display configuration
        property_name:
          displayName: "Display Name"

      summaries:         # Optional - custom aggregations
        summary_name: "aggregation expression"

      views:             # Required - at least one view
        - type: table
          name: "View Name"
          filters: ...
          order: ...
      ```

      ## Property Types

      | Type | Syntax | Examples | Description |
      |------|--------|----------|-------------|
      | **Note** | `property` or `note.property` | `status`, `author`, `note.title` | From note frontmatter YAML |
      | **File** | `file.property` | `file.name`, `file.mtime`, `file.tags` | File metadata (all file types) |
      | **Formula** | `formula.name` | `formula.days_old`, `formula.total` | Computed in base definition |

      ### Key File Properties

      | Property | Type | Description |
      |----------|------|-------------|
      | `file.name` | String | File name without extension |
      | `file.path` | String | Full path to file |
      | `file.folder` | String | Parent folder path |
      | `file.ext` | String | File extension |
      | `file.ctime` | Date | Creation time |
      | `file.mtime` | Date | Last modified time |
      | `file.size` | Number | File size in bytes |
      | `file.tags` | List | All tags (content + frontmatter) |
      | `file.links` | List | All internal links |
      | `file.embeds` | List | All embeds |

      ## Filters

      Filters narrow down which files appear in the view. Use at global level (applies to all views) or view level (specific view only).

      ### Filter Structure

      ```yaml
      filters:
        and:                              # All conditions must be true
          - file.hasTag("project")
          - 'status != "done"'
        or:                               # At least one condition true
          - file.inFolder("Work")
          - file.hasLink("Important")
        not:                              # Invert conditions
          - file.hasTag("archived")
      ```

      ### Operators

      **Comparison**: `==`, `!=`, `>`, `<`, `>=`, `<=`
      **Boolean**: `&&` (and), `||` (or), `!` (not)
      **Arithmetic**: `+`, `-`, `*`, `/`, `%`, `( )`

      ### Common Filter Patterns

      ```yaml
      # Files modified in last 7 days
      file.mtime > now() - "7d"

      # Files with specific tag
      file.hasTag("important")

      # Files in specific folder
      file.inFolder("Projects")

      # Files linking to specific note
      file.hasLink("Index")

      # Combine multiple conditions
      and:
        - file.hasTag("active")
        - 'status == "in-progress"'
        - file.mtime > now() - "1M"
      ```

      ### Using `this` for Context

      Use `this` to reference the current context:
      - In sidebar: refers to active file in main area
      - Embedded in note: refers to the note containing the base
      - Standalone base: refers to the base file itself

      ```yaml
      # Show files linking to current note (like backlinks)
      filters:
        file.hasLink(this.file)
      ```

      ## Views

      Each base can have multiple views with different layouts and filters.

      ### View Types

      - **table**: Rows are files, columns are properties
      - **list**: Bulleted or numbered file list
      - **cards**: Grid layout, great for galleries
      - **map**: Geographic pins (requires location properties)

      ### View Configuration

      ```yaml
      views:
        - type: table
          name: "View Name"         # Display name
          limit: 50                 # Max rows/items
          filters:                  # View-specific filters
            and: [...]
          order:                    # Sort order (array of properties)
            - priority
            - file.mtime
          groupBy:                  # Group by property
            property: status
            direction: ASC          # ASC or DESC
          summaries:                # Property → summary mapping
            count: Unique
            total: Sum
      ```

      ## Formulas

      Computed properties using expressions and functions.

      ```yaml
      formulas:
        # Days since file creation
        days_old: '(now() - file.ctime) / (1000 * 60 * 60 * 24)'

        # Format date as YYYY-MM-DD
        formatted_date: 'file.mtime.format("YYYY-MM-DD")'

        # Count links
        link_count: 'file.links.length'

        # Conditional logic
        status_icon: 'if(status == "done", "✅", if(status == "in-progress", "🔄", "⏳"))'

        # Calculate from properties
        total_price: 'price * quantity'

        # Check if overdue
        is_overdue: 'due < now()'
      ```

      **Access formulas in filters/views**: Use `formula.` prefix (e.g., `formula.days_old`)

      **Functions**: See full reference at https://help.obsidian.md/bases/functions

      ## Date Arithmetic

      Modify dates by adding/subtracting durations:

      ```yaml
      # Duration units: y/year, M/month, w/week, d/day, h/hour, m/minute, s/second

      now() + "1 day"              # 24 hours from now
      today() + "1M"               # One month from today
      file.mtime - "2w"            # Two weeks before modification

      # Comparisons
      file.mtime > now() - "7d"    # Modified within last week
      due < now()                  # Overdue items

      # Extract portions
      file.mtime.date()            # Date portion only
      file.ctime.format("YYYY-MM-DD HH:mm")
      ```

      ## Summaries

      Aggregate data across all rows in a view.

      ### Default Summary Formulas

      **Numeric**: Average, Sum, Min, Max, Range, Median, Stddev
      **Date**: Earliest, Latest, Range
      **Boolean**: Checked, Unchecked
      **Any**: Empty, Filled, Unique

      ### Using Summaries

      ```yaml
      views:
        - type: table
          name: Task Summary
          summaries:
            file.name: Unique        # Count unique files
            priority: Filled         # Count non-empty priorities
            estimate: Sum            # Total estimate hours
            due: Earliest            # Earliest due date
      ```

      ### Custom Summaries

      ```yaml
      summaries:
        customAvg: 'values.mean().round(2)'
        percentComplete: '(values.filter(v => v == "done").length / values.length * 100).toFixed(1)'
      ```

      ## Templates

      ### Template 1: Project Task Tracker

      Track tasks with status, priority, assignees, and due dates.

      **Required Note Properties**:
      ```yaml
      ---
      status: todo               # todo, in-progress, done, blocked
      priority: medium           # low, medium, high, urgent
      assignee: Name
      due: 2025-01-15
      estimate: 3                # hours
      tags: [project, work]
      ---
      ```

      **Standalone .base file** (`tasks.base`):
      ```yaml
      filters:
        and:
          - file.hasTag("project")
          - 'status != "done"'

      formulas:
        days_until_due: '(due - now()) / (1000 * 60 * 60 * 24)'
        is_overdue: 'due < now()'
        status_icon: 'if(status == "done", "✅", if(status == "in-progress", "🔄", if(status == "blocked", "🚫", "⏳")))'

      properties:
        status:
          displayName: Status
        priority:
          displayName: Priority
        formula.days_until_due:
          displayName: Days Until Due
        formula.status_icon:
          displayName: ""

      views:
        - type: table
          name: Active Tasks
          filters:
            and:
              - 'status != "done"'
          order:
            - priority
            - due
            - file.name
          groupBy:
            property: status
            direction: ASC
          summaries:
            file.name: Unique
            estimate: Sum

        - type: cards
          name: Task Board
          groupBy:
            property: status
            direction: ASC
      ```

      **Embedded version**:
      ````markdown
      ```base
      filters:
        and:
          - file.hasTag("project")
          - 'status != "done"'
      views:
        - type: table
          name: My Tasks
          order:
            - due
            - priority
      ```
      ````

      ### Template 2: Reading List / Content Database

      Track books, articles, videos, or any content with ratings and progress.

      **Required Note Properties**:
      ```yaml
      ---
      type: book                 # book, article, video, podcast
      author: Author Name
      status: reading            # to-read, reading, completed
      rating: 4                  # 1-5 stars
      started: 2025-01-01
      completed: 2025-01-15
      topics: [productivity, tech]
      tags: [reading]
      ---
      ```

      **Standalone .base file** (`reading.base`):
      ```yaml
      filters:
        file.hasTag("reading")

      formulas:
        rating_stars: 'if(rating, "⭐".repeat(rating), "")'
        days_to_complete: '(completed - started) / (1000 * 60 * 60 * 24)'
        status_badge: 'if(status == "completed", "✅ Done", if(status == "reading", "📖 Reading", "📚 To Read"))'

      properties:
        type:
          displayName: Type
        author:
          displayName: Author
        formula.rating_stars:
          displayName: Rating
        formula.status_badge:
          displayName: Status

      views:
        - type: table
          name: All Content
          order:
            - status
            - rating
            - completed
          groupBy:
            property: type
            direction: ASC
          summaries:
            file.name: Unique
            rating: Average

        - type: cards
          name: Gallery
          filters:
            'status == "completed"'
          order:
            - rating

        - type: list
          name: Currently Reading
          filters:
            'status == "reading"'
      ```

      **Embedded version**:
      ````markdown
      ```base
      filters:
        and:
          - file.hasTag("reading")
          - 'status == "reading"'
      views:
        - type: table
          name: Currently Reading
          order:
            - started
      ```
      ````

      ### Template 3: Knowledge/Note Index

      Browse and organize notes by topic, tags, and modification dates.

      **Required Note Properties**:
      ```yaml
      ---
      topic: Technology          # Main topic/category
      subtopic: AI               # Optional subcategory
      stage: seedling            # seedling, budding, evergreen
      tags: [notes, tech, ai]
      ---
      ```

      **Standalone .base file** (`notes.base`):
      ```yaml
      filters:
        file.hasTag("notes")

      formulas:
        days_since_update: 'Math.floor((now() - file.mtime) / (1000 * 60 * 60 * 24))'
        backlink_count: 'file.backlinks.length'
        last_updated: 'file.mtime.format("YYYY-MM-DD")'
        stage_icon: 'if(stage == "evergreen", "🌲", if(stage == "budding", "🌱", "🌰"))'

      properties:
        topic:
          displayName: Topic
        formula.stage_icon:
          displayName: ""
        formula.last_updated:
          displayName: Last Updated
        formula.days_since_update:
          displayName: Days Since Update

      views:
        - type: table
          name: All Notes
          order:
            - topic
            - file.mtime
          groupBy:
            property: topic
            direction: ASC
          summaries:
            file.name: Unique

        - type: table
          name: Recently Modified
          order:
            - file.mtime
          limit: 20
          filters:
            file.mtime > now() - "30d"

        - type: cards
          name: By Stage
          groupBy:
            property: stage
            direction: ASC
      ```

      **Embedded version**:
      ````markdown
      ```base
      filters:
        and:
          - file.hasTag("notes")
          - file.mtime > now() - "7d"
      views:
        - type: list
          name: Recent Notes
          order:
            - file.mtime
      ```
      ````

      ### Template 4: Minimal/General Template

      Flexible starting point for custom bases.

      ```yaml
      # Optional: Filter files
      filters:
        file.hasTag("your-tag")

      # Optional: Add computed properties
      formulas:
        example_formula: 'file.links.length'

      # Optional: Configure display names
      properties:
        your_property:
          displayName: "Your Property"

      # Required: At least one view
      views:
        - type: table
          name: "Main View"
          order:
            - file.name
          # Optional view-specific filters
          filters:
            'your_property != null'
          # Optional grouping
          groupBy:
            property: your_property
            direction: ASC
          # Optional summaries
          summaries:
            file.name: Unique
      ```

      ## Common Functions

      ### File Functions
      - `file.hasTag("tag")` - Check if file has tag
      - `file.hasLink("note")` - Check if file links to note
      - `file.inFolder("path")` - Check if file in folder

      ### String Functions
      - `property.length` - String/array length
      - `property.toUpperCase()` - Convert to uppercase
      - `property.toLowerCase()` - Convert to lowercase
      - `property.contains("text")` - Check if contains text

      ### Number Functions
      - `property.toFixed(2)` - Format to 2 decimals
      - `Math.floor(value)` - Round down
      - `Math.ceil(value)` - Round up
      - `Math.round(value)` - Round to nearest

      ### Date Functions
      - `now()` - Current date and time
      - `today()` - Current date (no time)
      - `date("2025-01-15")` - Parse date string
      - `property.format("YYYY-MM-DD")` - Format date
      - `property.date()` - Extract date portion

      ### Array Functions
      - `property.length` - Array length
      - `property.contains(value)` - Check if contains value
      - `property.join(", ")` - Join array to string
      - `values.mean()` - Mean (in summaries)
      - `values.filter(v => v > 5)` - Filter values

      ### Logic Functions
      - `if(condition, trueValue, falseValue)` - Conditional
      - `link("filename")` - Create link
      - `icon("icon-name")` - Insert icon

      **Full reference**: https://help.obsidian.md/bases/functions

      ## Best Practices

      ### Performance
      - Use `file.links` instead of `file.backlinks` (faster)
      - Filter at global level when possible
      - Avoid `file.properties` in large vaults
      - Limit use of backlinks in formulas

      ### Organization
      - Use meaningful formula names (`days_old` not `f1`)
      - Group related filters with `and`/`or`
      - Add comments in standalone .base files
      - Keep formulas simple and readable

      ### Maintainability
      - Test filters with small datasets first
      - Use properties consistently across notes
      - Document required properties for templates
      - Create reusable .base files for common views

      ### User Experience
      - Set meaningful display names
      - Use icons/emojis sparingly for visual interest
      - Group related views in same .base file
      - Order properties logically (most → least important)

      ## Quick Reference

      ### File a Bug or Request
      Create bases in your vault, or ask Claude to generate custom base syntax!

      ### Essential Syntax
      ```yaml
      # Minimal base
      views:
        - type: table
          name: My View

      # With filters
      filters:
        file.hasTag("tag")

      # With formula
      formulas:
        calc: 'property * 2'

      # With grouping
      views:
        - type: table
          name: Grouped
          groupBy:
            property: category
            direction: ASC
      ```

      ### Common Patterns
      ```yaml
      # Recent files
      file.mtime > now() - "7d"

      # Has property
      property != null

      # Multiple tags
      and:
        - file.hasTag("tag1")
        - file.hasTag("tag2")

      # Specific folder
      file.inFolder("Folder/Subfolder")

      # Links to note
      file.hasLink("Note Name")
      ```
    '';
  };
}
