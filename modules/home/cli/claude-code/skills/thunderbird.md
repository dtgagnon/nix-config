---
name: thunderbird
description: Interact with Thunderbird email using CLI, notmuch search, and direct Maildir access
---

# Thunderbird Email Management

Access email via Thunderbird CLI (compose), notmuch (search/read/tag), and direct Maildir files.

## Email Storage

**Location**: `~/Mail/`

```
~/Mail/
├── gagnon.derek@gmail.com/      # Personal Gmail
├── gagnon.derek@protonmail.com/ # Proton Mail
├── dgagnon@awrightpath.net/     # Awrightpath
├── dgagnon@stsdiesel.com/       # STSDiesel
└── local/                       # Local Folders
```

**Maildir structure**: `<account>/<folder>/{cur,new,tmp}/`
- `cur/` - Read messages
- `new/` - Unread messages
- Filename flags: `:2,S` (seen), `:2,R` (replied), `:2,F` (flagged)

## Composing Email

### Thunderbird CLI (opens UI)

```bash
# Basic
thunderbird -compose "to='user@example.com',subject='Subject',body='Body'"

# With attachment
thunderbird -compose "to='user@example.com',subject='Report',attachment='/path/file.pdf'"

# Multiple recipients, specific sender
thunderbird -compose "to='a@x.com,b@x.com',cc='c@x.com',from='gagnon.derek@gmail.com',subject='Subject'"
```

### msmtp (automated, no UI)

```bash
cat > /tmp/email.txt <<EOF
To: user@example.com
Subject: Automated Report
From: gagnon.derek@gmail.com

Body here.
EOF
msmtp -a default user@example.com < /tmp/email.txt
```

## Notmuch Search

**Database**: `~/.notmuch/` | **Update index**: `notmuch new`

### Query Fields

`from:user@example.com` - search by sender
`to:me@example.com` - search by recipient
`subject:invoice` - search subject line
`body:"keyword"` - search message body
`tag:inbox`, `tag:gmail` - search by tag
`date:today`, `date:2026-01..` - date or range
`path:**/INBOX/**` - file path pattern
`id:<message-id>` - specific message ID
`thread:<thread-id>` - specific thread

**Operators**: `AND` (default, space), `OR`, `NOT`, `()`

**Date formats**: `today`, `yesterday`, `YYYY-MM-DD`, `YYYY-MM-DD..`, `..YYYY-MM-DD`, `YYYY-MM-DD..YYYY-MM-DD`

### Account Tags

Emails are auto-tagged by account:
- `tag:gmail` - gagnon.derek@gmail.com
- `tag:proton` - gagnon.derek@protonmail.com
- `tag:awrightpath` - dgagnon@awrightpath.net
- `tag:stsdiesel` - dgagnon@stsdiesel.com
- `tag:local` - local folders

### Search Commands

```bash
notmuch search <query>                    # Search, returns thread summaries
notmuch count <query>                     # Count matching messages
notmuch search --output=messages <query>  # Get message IDs
notmuch search --output=threads <query>   # Get thread IDs
notmuch search --format=json <query>      # JSON output for parsing
```

## Reading Email

```bash
# Get message ID
ID=$(notmuch search --output=messages from:client subject:proposal | head -1)

# Show content
notmuch show "$ID"                    # Full message
notmuch show --format=text "$ID"      # Text only
notmuch show --format=json "$ID"      # JSON (for parsing)

# Show thread
THREAD=$(notmuch search --output=threads subject:invoice | head -1)
notmuch show "$THREAD"

# Extract fields with jq
notmuch show --format=json "$ID" | jq -r '.[0][0][0].headers'
notmuch show --format=json "$ID" | jq -r '.[0][0][0].body[0].content'
```

## Tagging

```bash
# Add tags
notmuch tag +important -- id:<message-id>
notmuch tag +followup +work -- from:boss@company.com

# Remove tags
notmuch tag -inbox +archived -- date:..2025-12-31
notmuch tag -unread -- tag:spam

# List all tags
notmuch search --output=tags '*'
```

## Direct Maildir Access

```bash
# Search with ripgrep (fast for simple searches)
rg -i "keyword" ~/Mail/*/INBOX/cur/
rg "^From: user@example.com" ~/Mail/*/*/cur/
rg "^Subject: .*invoice" ~/Mail/*/*/cur/

# List recent emails
find ~/Mail/*/INBOX/cur/ -type f -printf '%T@ %p\n' | sort -rn | head -10

# Count per account
find ~/Mail/gagnon.derek@gmail.com/INBOX/cur/ -type f | wc -l

# Read directly (RFC 822 format)
cat ~/Mail/gagnon.derek@gmail.com/INBOX/cur/1234567890.12345_1.hostname:2,S
```

## Folder Management

```bash
# Create folder (Maildir structure required)
mkdir -p ~/Mail/gagnon.derek@gmail.com/Archive/{cur,new,tmp}

# Move email between folders
mv ~/Mail/.../INBOX/cur/msg ~/Mail/.../Archive/cur/
notmuch new  # Update index

# List folders
ls -d ~/Mail/gagnon.derek@gmail.com/*/
```

## Workflow: Find → Read → Reply

```bash
# 1. Search
notmuch search from:client@example.com subject:proposal

# 2. Get ID and read
ID=$(notmuch search --output=messages from:client subject:proposal | head -1)
notmuch show --format=text "$ID"

# 3. Reply
thunderbird -compose "to='client@example.com',subject='Re: Proposal',body='Response'"
```

## Monitoring

```bash
# Unread count
notmuch count tag:inbox AND tag:unread

# Per account
notmuch count tag:gmail AND tag:inbox AND tag:unread

# List unread
notmuch search tag:inbox AND tag:unread

# Watch for new mail
inotifywait -m -r -e create ~/Mail/*/INBOX/new/
```

## Bulk Operations

```bash
# Tag old mail as archived
notmuch tag +archived -inbox -- date:..2025-12-31

# Export to mbox
notmuch show --format=mbox subject:report > /tmp/reports.mbox

# Delete old spam
find ~/Mail/*/Junk/cur/ -type f -mtime +30 -delete
notmuch new
```

## Thunderbird Databases

`~/.thunderbird/dtgagnon/global-messages-db.sqlite` - Gloda search index
`~/.thunderbird/dtgagnon/abook.sqlite` - contacts/address book
`~/.thunderbird/dtgagnon/prefs.js` - preferences/settings

```bash
# Query Gloda database
sqlite3 ~/.thunderbird/dtgagnon/global-messages-db.sqlite \
  "SELECT subject, date FROM messages WHERE subject LIKE '%invoice%' LIMIT 10;"
```

## Attachments

```bash
# Using mblaze
mshow -t /path/to/email/file    # List attachments
mshow -x /path/to/email/file    # Extract all
```

## Key Commands

```bash
notmuch new              # Update index after new mail
notmuch compact          # Compact database
notmuch count '*'        # Database stats (total messages)
notmuch config list      # Show configuration
rm ~/Mail/*/*.msf        # Delete Thunderbird indexes (rebuilds on restart)
```

## Notes

- **Concurrent access**: Maildir is safe for simultaneous Thunderbird + CLI use
- **Tag storage**: Notmuch tags in `~/.notmuch/` (separate from Thunderbird)
- **Sync**: Changes via notmuch detected by Thunderbird on next sync
- **Backups**: Include `~/Mail/` (data) and `~/.notmuch/` (index)
