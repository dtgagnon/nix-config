---
name: emma-actions
description: Review and manage action items extracted from emails
---

# Emma Action Items

Manage tasks and action items extracted from emails.

## Instructions

When the user invokes this skill, help them review and manage action items.

### List Action Items

```bash
# All pending
emma actions list --status pending

# By priority
emma actions list --priority urgent
emma actions list --priority high

# By status
emma actions list --status in_progress
emma actions list --status completed
```

### View Details

```bash
emma actions show <id>
```

Shows:
- Title and description
- Priority and urgency
- Due date (if set)
- Source email reference
- Creation timestamp

### Update Status

```bash
# Mark as completed
emma actions complete <id>

# Dismiss (not needed)
emma actions dismiss <id>
```

### Workflow

1. **Review pending items**: `emma actions list --status pending`
2. **Check urgent first**: `emma actions list --priority urgent`
3. **View details**: `emma actions show <id>`
4. **Take action** (external to emma)
5. **Mark complete**: `emma actions complete <id>`

## Example Session

User: "/emma-actions"

1. Run `emma actions list --status pending --limit 10`
2. Show the user their pending action items
3. If they have urgent items, highlight those
4. Ask which items they'd like to work on or mark complete
5. For completion: `emma actions complete <id>`
6. For dismissal: `emma actions dismiss <id>`

## Integration with Analysis

Action items are automatically extracted when analyzing emails:

```bash
# This extracts action items if found
emma analyze email <id>

# Then view extracted items
emma actions list --status pending
```

## Tips

- Action items persist in Emma's database
- Items are linked to their source emails
- Use `--priority urgent` to focus on time-sensitive tasks
- Dismissed items can be filtered out with `--status pending`
