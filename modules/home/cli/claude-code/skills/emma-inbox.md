---
name: emma-inbox
description: Quick inbox review - list recent emails and generate summaries
---

# Emma Inbox Review

Quick check of recent inbox emails with optional LLM summaries.

## Instructions

When the user invokes this skill:

1. **List recent emails** from the default inbox:
   ```bash
   emma email list --folder INBOX --limit 10
   ```

2. **If user wants details** on specific emails, use:
   ```bash
   emma analyze summarize <email-id>
   ```

3. **For full analysis** of an email:
   ```bash
   emma analyze email <email-id>
   ```

## Quick Commands

```bash
# List inbox (uses default source)
emma email list --limit 20

# Interactive browse
emma email show

# Summarize specific email
emma analyze summarize <id>

# Check unprocessed count
emma service status
```

## Example Session

User: "/emma-inbox"

1. Run `emma email list --folder INBOX --limit 10`
2. Show the user the list of recent emails
3. Ask if they want to analyze any specific emails
4. If yes, run `emma analyze email <selected-id>` or `emma analyze summarize <selected-id>`
