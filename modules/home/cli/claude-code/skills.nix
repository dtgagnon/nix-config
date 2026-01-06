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

    home.file.".claude/skills/thunderbird/SKILL.md".text = ''
      ---
      name: thunderbird
      description: Interact with Thunderbird email using CLI, notmuch search, and direct Maildir access
      ---

      # Thunderbird Email Management

      Comprehensive email interaction for the current user's Thunderbird setup using:
      - **Thunderbird CLI** - Composing and sending
      - **Notmuch** - Search, read, tag/organize
      - **Maildir** - Direct file access for advanced operations
      - **SQLite databases** - Metadata queries

      ## Email Storage Structure

      **Maildir location**: `~/Mail/`

      Each account uses Maildir format (one file per message):
      ```
      ~/Mail/
      ├── gagnon.derek@gmail.com/           # Personal Gmail
      ├── gagnon.derek@protonmail.com/      # Proton Mail
      ├── dgagnon@awrightpath.net/          # Awrightpath
      ├── dgagnon@stsdiesel.com/            # STSDiesel
      └── local/                            # Local Folders
      ```

      **Maildir structure per folder**:
      ```
      <account>/<folder>/
      ├── cur/         # Current messages (read, flagged, etc.)
      ├── new/         # Unread messages
      └── tmp/         # Temporary
      ```

      **Maildir flags** (in filename):
      - `:2,S` - Seen (read)
      - `:2,R` - Replied
      - `:2,F` - Flagged
      - `:2,D` - Draft
      - `:2,T` - Trashed

      **Index files**:
      - `.msf` files - Thunderbird's Mork indexes (can be deleted to rebuild)

      ## Composing and Sending Email

      ### Using Thunderbird CLI

      **Compose new email**:
      ```bash
      thunderbird -compose "to='user@example.com',subject='Subject',body='Body text'"
      ```

      **With attachments**:
      ```bash
      thunderbird -compose "to='user@example.com',subject='Report',body='See attached',attachment='/path/to/file.pdf'"
      ```

      **Multiple recipients**:
      ```bash
      thunderbird -compose "to='user1@example.com,user2@example.com',cc='user3@example.com',subject='Subject',body='Body'"
      ```

      **From specific account**:
      ```bash
      thunderbird -compose "to='user@example.com',subject='Subject',body='Body',from='gagnon.derek@gmail.com'"
      ```

      **Notes**:
      - Opens composition window in Thunderbird (must be running or will start)
      - User can edit before sending
      - For automated sending without UI, use `msmtp` instead

      ### Direct SMTP Sending (msmtp)

      For automated/scripted sending without Thunderbird UI:

      ```bash
      # Create message file
      cat > /tmp/email.txt <<EOF
      To: user@example.com
      Subject: Automated Report
      From: gagnon.derek@gmail.com

      Email body here.
      EOF

      # Send via msmtp (configured in Thunderbird's SMTP settings)
      msmtp -a default user@example.com < /tmp/email.txt
      ```

      ## Searching and Reading Email

      ### Notmuch Search

      **Notmuch database**: `~/.notmuch/` (indexes all accounts in `~/Mail/`)

      **Update index** (run after new mail arrives):
      ```bash
      notmuch new
      ```

      **Basic search**:
      ```bash
      # Search by sender
      notmuch search from:user@example.com

      # Search by subject
      notmuch search subject:invoice

      # Search body content
      notmuch search body:"important keyword"

      # Search by date
      notmuch search date:today
      notmuch search date:yesterday..
      notmuch search date:2026-01-01..2026-01-31

      # Search by tag
      notmuch search tag:inbox
      notmuch search tag:gmail
      ```

      **Combined searches**:
      ```bash
      # AND (space-separated)
      notmuch search from:user@example.com subject:invoice

      # OR
      notmuch search from:user1@example.com OR from:user2@example.com

      # NOT
      notmuch search NOT tag:spam

      # Complex queries
      notmuch search "from:user@example.com AND subject:invoice AND date:2026-01.."
      ```

      **Account-specific searches** (using auto-tagged accounts):
      ```bash
      notmuch search tag:gmail          # Personal Gmail
      notmuch search tag:proton         # Proton Mail
      notmuch search tag:awrightpath    # Awrightpath
      notmuch search tag:stsdiesel      # STSDiesel
      notmuch search tag:local          # Local Folders
      ```

      **Search output formats**:
      ```bash
      # Default: thread summaries
      notmuch search subject:test

      # JSON (for parsing)
      notmuch search --format=json subject:test

      # Count only
      notmuch count subject:test

      # Get message IDs
      notmuch search --output=messages subject:test
      ```

      ### Reading Email Content

      **Show full email** (from search result):
      ```bash
      # Get message ID from search
      ID=$(notmuch search --output=messages from:user@example.com | head -1)

      # Show email content
      notmuch show "$ID"

      # JSON format (for parsing)
      notmuch show --format=json "$ID"

      # Just body text
      notmuch show --format=text "$ID"
      ```

      **Show email thread**:
      ```bash
      # Get thread ID
      THREAD=$(notmuch search --output=threads subject:invoice | head -1)

      # Show entire thread
      notmuch show "$THREAD"
      ```

      **Extract specific fields**:
      ```bash
      # Using jq to parse JSON
      notmuch show --format=json "$ID" | jq -r '.[0][0][0].headers'
      notmuch show --format=json "$ID" | jq -r '.[0][0][0].body[0].content'
      ```

      ### Direct Maildir Access

      **Find emails by grep** (fast for simple searches):
      ```bash
      # Search all mail for keyword
      rg -i "keyword" ~/Mail/*/INBOX/cur/

      # Find by sender
      rg "^From: user@example.com" ~/Mail/*/*/cur/

      # Find by subject
      rg "^Subject: .*invoice" ~/Mail/*/*/cur/
      ```

      **List recent emails**:
      ```bash
      # Most recently modified (10 newest)
      find ~/Mail/*/INBOX/cur/ -type f -printf '%T@ %p\n' | sort -rn | head -10

      # Count emails per account
      find ~/Mail/gagnon.derek@gmail.com/INBOX/cur/ -type f | wc -l
      ```

      **Read email file directly**:
      ```bash
      # Emails are standard RFC 822 format
      cat ~/Mail/gagnon.derek@gmail.com/INBOX/cur/1234567890.12345_1.hostname:2,S
      ```

      ## Email Organization

      ### Tagging with Notmuch

      **Add tags**:
      ```bash
      # Tag specific message
      notmuch tag +important -- id:<message-id>

      # Tag search results
      notmuch tag +followup -- from:boss@company.com AND NOT tag:done

      # Multiple tags
      notmuch tag +work +urgent -- subject:"critical issue"
      ```

      **Remove tags**:
      ```bash
      notmuch tag -inbox +archived -- date:..2025-12-31
      notmuch tag -unread -- tag:spam
      ```

      **List all tags**:
      ```bash
      notmuch search --output=tags '*'
      ```

      **Search by tag**:
      ```bash
      notmuch search tag:important
      notmuch search tag:work AND tag:urgent
      ```

      **Auto-tagging** (configured in NixOS module):
      - New emails auto-tagged by account: `+gmail`, `+proton`, `+awrightpath`, `+stsdiesel`, `+local`
      - All new emails tagged `+inbox`

      ### Folders (Maildir Directories)

      **Create new folder**:
      ```bash
      # Maildir structure required
      mkdir -p ~/Mail/gagnon.derek@gmail.com/Archive/{cur,new,tmp}

      # Thunderbird will auto-detect on next startup
      ```

      **Move email between folders**:
      ```bash
      # Move from INBOX to Archive
      mv ~/Mail/gagnon.derek@gmail.com/INBOX/cur/1234.msg \
         ~/Mail/gagnon.derek@gmail.com/Archive/cur/

      # Update notmuch index
      notmuch new
      ```

      **List folders per account**:
      ```bash
      ls -d ~/Mail/gagnon.derek@gmail.com/*/
      ```

      ### Message Filters

      **Thunderbird filters**: `~/.thunderbird/dtgagnon/ImapMail/<account>/msgFilterRules.dat`

      **Format** (simple text file):
      ```
      version="9"
      logging="no"
      name="Move to Archive"
      enabled="yes"
      type="17"
      action="Move to folder"
      actionValue="mailbox://nobody@imap.gmail.com/Archive"
      condition="AND (from,contains,old@example.com)"
      ```

      **Common filter actions**:
      - `Move to folder` - Move to folder
      - `Copy to folder` - Copy to folder
      - `Delete` - Delete message
      - `Mark as read` - Mark read
      - `Add tag` - Add tag/label

      **Conditions**:
      - `from,contains,user@example.com`
      - `subject,contains,invoice`
      - `to,is,me@example.com`
      - `body,contains,keyword`

      **Reload filters**:
      - Restart Thunderbird or
      - Edit via Thunderbird UI (Tools → Message Filters)

      ## Monitoring Mail Arrival

      ### Watch for new mail

      **Monitor Maildir**:
      ```bash
      # Watch all INBOX/new directories
      inotifywait -m -r -e create ~/Mail/*/INBOX/new/
      ```

      **Notmuch hook** (auto-runs on `notmuch new`):
      ```bash
      # Configured in NixOS module: ~/.config/notmuch/default/hooks/post-new
      # Automatically tags new mail by account
      ```

      **Check unread count**:
      ```bash
      # Via notmuch
      notmuch count tag:inbox AND tag:unread

      # Per account
      notmuch count tag:gmail AND tag:inbox
      ```

      **List unread messages**:
      ```bash
      notmuch search tag:inbox AND tag:unread
      ```

      ## Thunderbird Databases

      ### Global Messages Database

      **Location**: `~/.thunderbird/dtgagnon/global-messages-db.sqlite`

      **Purpose**: Full-text search index (Gloda) for Thunderbird's built-in search

      **Query examples**:
      ```bash
      # Open database
      sqlite3 ~/.thunderbird/dtgagnon/global-messages-db.sqlite

      # List indexed messages
      SELECT subject, date FROM messages LIMIT 10;

      # Search by subject
      SELECT subject, date, jsonAttributes FROM messages
      WHERE subject LIKE '%invoice%';

      # Count messages by folder
      SELECT folderID, COUNT(*) FROM messages GROUP BY folderID;
      ```

      **Tables**:
      - `messages` - Indexed messages
      - `messageAttributes` - Message metadata
      - `folderLocations` - Folder paths
      - `identities` - Email identities
      - `conversations` - Thread groupings

      **Note**: Gloda and notmuch are separate indexes. Use notmuch for CLI/LLM access.

      ## Common Workflows

      ### Workflow 1: Find and Reply to Email

      ```bash
      # 1. Search for email
      notmuch search from:client@example.com subject:proposal

      # 2. Get message ID
      ID=$(notmuch search --output=messages from:client@example.com subject:proposal | head -1)

      # 3. Read content
      notmuch show --format=text "$ID"

      # 4. Compose reply
      thunderbird -compose "to='client@example.com',subject='Re: Proposal',body='Response here'"
      ```

      ### Workflow 2: Bulk Tag Old Messages

      ```bash
      # Tag all emails from 2025 as archived
      notmuch tag +archived -inbox -- date:2025-01-01..2025-12-31

      # Tag all emails from specific sender
      notmuch tag +client +important -- from:client@example.com

      # Tag unread emails from specific folder
      notmuch tag +urgent -- path:**/Urgent/** AND tag:unread
      ```

      ### Workflow 3: Export Emails

      ```bash
      # Get all emails matching criteria
      notmuch search --output=files subject:report > /tmp/email-list.txt

      # Copy to export directory
      mkdir -p /tmp/email-export
      cat /tmp/email-list.txt | xargs -I {} cp {} /tmp/email-export/

      # Or create mbox archive
      notmuch show --format=mbox subject:report > /tmp/reports.mbox
      ```

      ### Workflow 4: Clean Up Spam

      ```bash
      # Tag as spam
      notmuch tag +spam -inbox -- from:spammer@example.com

      # Move to Junk folder (optional)
      # Note: Thunderbird's spam filter handles this automatically

      # Delete old spam
      find ~/Mail/*/Junk/cur/ -type f -mtime +30 -delete

      # Rebuild indexes
      notmuch new
      ```

      ## Advanced Operations

      ### Extract Attachments

      Using `mblaze` (Maildir utilities):
      ```bash
      # List attachments in email
      mshow -t /path/to/email/file

      # Extract all attachments
      mshow -x /path/to/email/file
      ```

      ### Search Performance

      **Notmuch is indexed** (fast):
      - Full-text search across all fields
      - Tag-based organization
      - Thread reconstruction

      **Ripgrep for ad-hoc** (slower but flexible):
      - Pattern matching in message files
      - No index to maintain
      - Good for one-off searches

      **Choose notmuch for**:
      - Repeated searches
      - Complex queries
      - Tag-based workflows
      - Thread viewing

      **Choose ripgrep for**:
      - Quick one-off searches
      - Regex pattern matching
      - Header-specific searches

      ### Thunderbird Profile Location

      - **Profile**: `~/.thunderbird/dtgagnon/`
      - **Preferences**: `~/.thunderbird/dtgagnon/prefs.js`
      - **Address book**: `~/.thunderbird/dtgagnon/abook.sqlite`
      - **Calendar**: `~/.thunderbird/dtgagnon/calendar-data/`

      ## Reference

      ### Notmuch Query Syntax

      **Fields**:
      - `from:` - Sender email
      - `to:` - Recipient email
      - `subject:` - Subject line
      - `body:` - Message body
      - `tag:` - Tags
      - `path:` - File path pattern
      - `folder:` - Folder name
      - `date:` - Date range
      - `id:` - Message ID
      - `thread:` - Thread ID

      **Operators**:
      - `AND` - Both conditions (default)
      - `OR` - Either condition
      - `NOT` - Negate condition
      - `()` - Grouping

      **Date syntax**:
      - `today`, `yesterday`
      - `YYYY-MM-DD` (exact date)
      - `YYYY-MM-DD..` (from date)
      - `..YYYY-MM-DD` (until date)
      - `YYYY-MM-DD..YYYY-MM-DD` (range)

      ### Useful Commands

      ```bash
      # Rebuild notmuch database
      notmuch new

      # Compact database
      notmuch compact

      # Show database stats
      notmuch count '*'

      # Dump entire database config
      notmuch config list

      # Restore Thunderbird indexes (if corrupted)
      rm ~/Mail/*/*.msf
      # Thunderbird will rebuild on next startup
      ```

      ## Integration Notes

      - **Concurrent access**: Maildir format allows safe Thunderbird + LLM access simultaneously
      - **Tag sync**: Notmuch tags are stored in `~/.notmuch/` database (separate from Thunderbird)
      - **Thunderbird changes**: Automatically detected by notmuch on next `notmuch new`
      - **LLM changes**: Moving/tagging via notmuch is safe, Thunderbird will sync
      - **Backups**: Include both `~/Mail/` (email data) and `~/.notmuch/` (search index)
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
