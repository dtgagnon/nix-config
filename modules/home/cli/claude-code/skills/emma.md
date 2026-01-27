---
name: emma
description: Email automation CLI with LLM analysis, digests, and action items
---

# Emma Email Agent

Emma (Email Management and Monitoring Assistant) provides LLM-powered email processing, organization, and automation.

## Quick Reference

```bash
# View emails (omit --source to use default)
emma email list --folder INBOX --limit 20
emma email list --source work --folder INBOX    # Specific account
emma email show                                  # Interactive selector

# Email operations
emma email move Archive                  # Interactive + dry-run
emma email move Archive --execute        # Actually move
emma email delete                        # Interactive, moves to Trash
emma email delete --permanent --execute  # Permanently delete

# LLM Analysis (understands sent vs received based on user email)
emma analyze email                       # Full analysis (category, priority, sentiment, etc.)
emma analyze summarize                   # Quick 1-2 sentence summary
emma analyze draft-reply                 # Generate reply draft

# Action items
emma actions list --status pending
emma actions complete <id>
emma actions dismiss <id>

# Digests
emma digest generate --hours 24
emma digest list
emma digest show <id>

# Service
emma service status
emma service run-once --monitor --digest
```

## Email Sources

Emma reads from configured Maildir or IMAP sources:

```bash
emma source list    # Show configured sources
emma config show    # Full config display
```

**Configuration**: `~/.config/emma/config.local.yaml`

Email address is the config key. Other fields are optional with smart defaults:

```yaml
maildir_accounts:
  alice@protonmail.com:
    default: true                    # Use when --source omitted
  alice@gmail.com:                   # Empty = all defaults
  alice@company.com:
    account_name: work               # Override source name (default: domain)

llm:
  provider: ollama
  model: gpt-oss:20b
  ollama_base_url: http://localhost:11434
```

**Defaults**:
- `account_name`: derived from domain (e.g., "protonmail", "gmail", "company")
- `path`: `~/Mail/<email_address>`
- `default`: false (first account used if none marked)

## Email Operations

### List and Browse

```bash
# List emails (uses default source if --source omitted)
emma email list --folder INBOX --limit 50
emma email list --source gmail --folder INBOX --limit 50

# Interactive browser (fzf-style)
emma email show                          # Default source
emma email show --source work            # Specific account
emma email show --source gmail INBOX     # Account + folder
```

### Move Emails

```bash
# Dry-run (shows what would happen)
emma email move Archive

# With specific email ID
emma email move Archive abc123 --execute

# From different folder
emma email move Archive --from-folder Sent --execute
```

### Delete Emails

```bash
# Move to Trash (default)
emma email delete

# Permanently delete
emma email delete --permanent --execute

# Specific email
emma email delete abc123 --execute
```

## LLM Analysis

### Full Analysis

Returns: category, priority, summary, sentiment, action_required, suggested_tags, key_points

```bash
emma analyze email                       # Interactive selection
emma analyze email abc123                # Specific email

# Output example:
# category: work
# priority: high
# summary: Request for quarterly report by Friday
# action_required: true
# suggested_response: Acknowledge and confirm delivery date
```

### Summarize

Quick 1-2 sentence summary:

```bash
emma analyze summarize
emma analyze summarize abc123
```

### Draft Reply

Creates a draft requiring approval:

```bash
emma analyze draft-reply
emma analyze draft-reply abc123 --instructions "polite decline"

# Manage drafts
emma draft list
emma draft show <draft-id>
emma draft approve <draft-id>
emma draft discard <draft-id>
```

## Action Items

Extracted tasks from emails with urgency tracking:

```bash
# List actions
emma actions list
emma actions list --status pending
emma actions list --priority urgent
emma actions list --status in_progress

# View details
emma actions show <id>

# Update status
emma actions complete <id>
emma actions dismiss <id>
```

**Statuses**: pending, in_progress, completed, dismissed
**Priorities**: low, normal, high, urgent

## Digests

Periodic email summaries:

```bash
# Generate now
emma digest generate                     # Default 12 hours
emma digest generate --hours 24
emma digest generate --hours 6 --force   # Even if below threshold

# View
emma digest list
emma digest show <id>
```

## Service (Background Processing)

Emma can run as a background service for continuous monitoring:

```bash
# Status
emma service status

# Run one cycle (for testing/cron)
emma service run-once --monitor --digest

# Start (foreground)
emma service start --foreground
```

**Service capabilities**:
- Monitor new emails and classify them
- Extract action items automatically
- Generate scheduled digests
- Track processed emails to avoid duplicates

## Audit Log

Track all email operations:

```bash
emma audit list
emma audit list --action move --limit 50
emma audit show <entry-id>
emma audit export --format json --output audit.json
```

## Common Workflows

### Triage Inbox

```bash
# 1. View recent emails (uses default source)
emma email show

# 2. Analyze interesting ones
emma analyze email

# 3. Move processed emails
emma email move Processed --execute
```

### Morning Review

```bash
# Generate overnight digest
emma digest generate --hours 12

# Check pending actions
emma actions list --status pending --priority high
```

### Process and Archive

```bash
# Analyze and extract actions
emma analyze email
# (creates action items if found)

# Move to archive
emma email move Archive --execute
```

### Draft and Review Replies

```bash
# Create draft
emma analyze draft-reply --instructions "brief, professional"

# Review
emma draft list
emma draft show <id>

# Approve or discard
emma draft approve <id>  # Ready to send manually
emma draft discard <id>  # Delete draft
```

## LLM Configuration

### Local (Ollama)

```yaml
llm:
  provider: ollama
  model: gpt-oss:20b
  max_tokens: 1024
  ollama_base_url: http://localhost:11434
  ollama_context_length: 24576
```

### Cloud (Anthropic)

```yaml
llm:
  provider: anthropic
  model: claude-sonnet-4-20250514
  max_tokens: 1024
```

Set `ANTHROPIC_API_KEY` environment variable.

## Notes

- **Dry-run default**: Most destructive operations require `--execute`
- **Interactive selectors**: fzf-style selection when no ID provided
- **Audit trail**: All operations logged when audit enabled
- **No auto-send**: Drafts require manual approval and sending
- **Source flexibility**: Works with Maildir (Thunderbird/mbsync) or IMAP
