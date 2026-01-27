---
name: emma-draft
description: Manage LLM-generated email reply drafts
---

# Emma Draft Management

Review and manage LLM-generated email reply drafts.

## Instructions

When the user invokes this skill, help them manage their draft replies.

### Create Drafts

Drafts are created via email analysis:

```bash
# Create draft for specific email
emma analyze draft-reply <email-id>

# With instructions
emma analyze draft-reply <email-id> --instructions "brief, polite decline"
emma analyze draft-reply <email-id> --instructions "request more details"
emma analyze draft-reply <email-id> --instructions "formal, professional tone"
```

### List Drafts

```bash
# All drafts
emma draft list

# By status
emma draft list --status pending_review
emma draft list --status approved
emma draft list --status discarded
```

### View Draft

```bash
emma draft show <draft-id>
```

Shows:
- Draft body text
- Original email subject
- Recipient
- Status
- Instructions used (if any)

### Approve or Discard

```bash
# Approve (marks ready for manual send)
emma draft approve <draft-id>

# Discard (delete draft)
emma draft discard <draft-id>
```

## Important Notes

- **No auto-send**: Emma never sends emails automatically
- **Approval required**: All drafts require explicit user approval
- **Manual send**: After approval, send via your email client
- **Audit logged**: All draft actions are recorded

## Workflow

1. **Analyze email and create draft**:
   ```bash
   emma analyze draft-reply <email-id> --instructions "concise response"
   ```

2. **Review the draft**:
   ```bash
   emma draft show <draft-id>
   ```

3. **Decide**:
   - Approve: `emma draft approve <draft-id>`
   - Discard and regenerate: `emma draft discard <draft-id>` then create new

4. **Send manually** via Thunderbird or email client

## Example Session

User: "/emma-draft"

1. List pending drafts: `emma draft list --status pending_review`
2. Show user the drafts awaiting review
3. For each: `emma draft show <id>` to display content
4. Ask: "Would you like to approve, discard, or regenerate?"
5. Take appropriate action

### Regenerating a Draft

If unsatisfied with a draft:

```bash
# Discard current
emma draft discard <draft-id>

# Create new with different instructions
emma analyze draft-reply <original-email-id> --instructions "more formal tone"
```
