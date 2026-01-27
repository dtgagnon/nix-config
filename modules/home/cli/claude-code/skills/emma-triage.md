---
name: emma-triage
description: Email triage workflow - analyze, categorize, and organize emails
---

# Emma Email Triage

Guided workflow for processing and organizing emails.

## Triage Workflow

When the user invokes this skill, guide them through email triage:

### Step 1: Review Inbox

```bash
emma email list --source default --folder INBOX --limit 20
```

### Step 2: Analyze Emails

For each email of interest:

```bash
# Full analysis (category, priority, action needed)
emma analyze email <id>
```

The analysis returns:
- **category**: personal, work, newsletter, promotional, transactional, spam, other
- **priority**: low, normal, high, urgent
- **action_required**: boolean
- **summary**: brief description
- **suggested_response**: if action needed

### Step 3: Take Action

Based on analysis:

**If action required:**
```bash
# Create draft reply
emma analyze draft-reply <id> --instructions "brief response"

# Review and approve draft
emma draft show <draft-id>
emma draft approve <draft-id>
```

**If newsletter/promotional:**
```bash
emma email move Newsletters <id> --execute
# or
emma email move Promotions <id> --execute
```

**If processed/archived:**
```bash
emma email move Archive <id> --execute
```

**If spam:**
```bash
emma email delete <id> --permanent --execute
```

### Step 4: Check Action Items

```bash
emma actions list --status pending
```

## Batch Processing

For multiple emails:

```bash
# Analyze several
emma analyze email <id1>
emma analyze email <id2>

# Move multiple (run for each)
emma email move Archive <id1> --execute
emma email move Archive <id2> --execute
```

## Example Session

1. "Let me check your inbox" -> `emma email list --limit 15`
2. "I see 3 emails that look important. Let me analyze them."
3. For each: `emma analyze email <id>`
4. "Email 1 needs a response. Let me draft a reply."
5. `emma analyze draft-reply <id1>`
6. "Email 2 is a newsletter, moving to Newsletters folder."
7. `emma email move Newsletters <id2> --execute`
8. "Email 3 is spam, deleting."
9. `emma email delete <id3> --permanent --execute`
