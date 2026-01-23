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
