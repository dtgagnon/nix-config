---
name: emma-digest
description: Generate and view email digest summaries
---

# Emma Email Digests

Generate and review email digest summaries.

## Instructions

When the user invokes this skill, help them generate or review email digests.

### Generate Digest

```bash
# Default (last 12 hours)
emma digest generate

# Custom period
emma digest generate --hours 24
emma digest generate --hours 6

# Force generation even if few emails
emma digest generate --force

# Generate without delivering
emma digest generate --no-deliver
```

### View Digests

```bash
# List recent
emma digest list --limit 10

# View specific digest
emma digest show <id>
```

### Digest Contents

A digest includes:
- **Period**: Time range covered
- **Email count**: Number of emails processed
- **Summary**: LLM-generated overview
- **Categories**: Breakdown by email type
- **Action items**: Extracted tasks

## Service Integration

Digests can be generated automatically by the Emma service:

```bash
# Check service status
emma service status

# Run digest manually via service
emma service run-once --digest

# Run both monitor and digest
emma service run-once --monitor --digest
```

### Scheduled Digests

Configure in `~/.config/emma/config.yaml`:

```yaml
service:
  enabled: true
  digest:
    enabled: true
    schedule: ["08:00", "18:00"]  # Twice daily
    min_emails: 3                  # Minimum to generate
```

## Example Session

User: "/emma-digest"

1. Ask: "Would you like to generate a new digest or view existing ones?"
2. For new digest: `emma digest generate --hours 24`
3. For existing: `emma digest list` then `emma digest show <id>`

### Morning Review

```bash
# Generate overnight digest
emma digest generate --hours 12

# View it
emma digest list
emma digest show <latest-id>
```

### Weekly Summary

```bash
# Generate weekly digest
emma digest generate --hours 168 --force
```
