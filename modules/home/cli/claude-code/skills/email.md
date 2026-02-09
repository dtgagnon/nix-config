---
name: email
description: Search, read, triage, and organize email via Maildir and notmuch
user_invocable: true
argument_hint: "[inbox [account]|search <query>|read <id|query>|triage [account]|sync]"
---

# /email — Maildir Email Workflows

Interactive and agentic email workflows backed by notmuch search/tag and Maildir access.

## Infrastructure

- **Maildir**: `~/Mail/<account>/` — one directory per account, synced by mbsync
- **mbsync**: IMAP sync on a 5-minute systemd timer. Manual sync: `mbsync -a && notmuch new`
- **notmuch**: Search, index, and tag engine. Database at `~/.notmuch/`
- **aerc**: TUI mail client for composing and replying — direct the user there for sending
- **emma**: Background LLM agent that classifies mail and generates digests via notmuch tags. Claude handles on-demand interactive analysis — complementing, not replacing, emma
- **Protonmail**: Routes through protonmail-bridge on localhost

**Constraint**: notmuch flag sync is disabled. Tags applied in notmuch do NOT propagate back to IMAP. This is by design — tags are local metadata.

## Maildir Discovery

Accounts are discovered at runtime — do not hardcode them.

```bash
ls ~/Mail/                                    # List accounts
ls ~/Mail/<account>/                          # List folders for an account
notmuch search --output=tags '*'              # Discover tag vocabulary (including emma's tags)
```

Each folder contains `cur/`, `new/`, `tmp/` subdirectories. Filename flags: `:2,S` (seen), `:2,R` (replied), `:2,F` (flagged).

## Subcommands

### `/email inbox [account]`

Review unread inbox. **Always delegate to subagent** (batch email reads).

Workflow:
1. Sync if requested or stale: `mbsync -a && notmuch new`
2. Count unread per account: `notmuch count tag:unread AND folder:<account>/INBOX` for each discovered account
3. Subagent reads unread messages (all accounts or filtered to `[account]`):
   ```bash
   notmuch show --format=json tag:unread AND folder:<account>/INBOX
   ```
4. Subagent returns: sender, subject, date, priority assessment, action needed — grouped by account
5. Present summary to user

Subagent prompt should request a synthesized summary (1,000–2,000 tokens), not raw message relay.

### `/email search <query>`

Search email with notmuch. **Runs directly** (notmuch output is compact).

```bash
notmuch search <query>                        # Thread summaries
notmuch search --format=json <query>          # JSON for parsing
notmuch count <query>                         # Count matches
```

For natural language queries, translate to notmuch syntax (see Query Reference below). Show results directly in compact format. If result count exceeds ~30, show count first and ask the user to narrow down.

### `/email read <id|query>`

Read a specific message or thread.

- **Single message / short thread (≤3 messages)**: Read directly.
- **Long thread (>3 messages)**: **Delegate to subagent** for synthesis.

```bash
notmuch show --format=json id:<message-id>    # Single message
notmuch show --format=json thread:<thread-id> # Full thread
```

Extract from JSON: `.[0][0][0].headers` for headers, `.[0][0][0].body[0].content` for body.

### `/email triage [account]`

Analyze unread mail, classify, tag, and summarize. **Always delegate to subagent**.

Workflow:
1. Subagent discovers existing tags: `notmuch search --output=tags '*'`
2. Reads all unread: `notmuch show --format=json tag:unread` (filtered by account if specified)
3. For each message, classifies:
   - **Category**: personal, work, newsletter, promotional, transactional, notification, spam
   - **Priority**: low, normal, high, urgent
   - **Action needed**: yes/no with brief description
4. Applies tags directly (no approval step): `notmuch tag +<category> +priority-<level> -- id:<msg-id>`
   - Before tagging, check existing tags on each message to avoid conflicting with emma's classifications
   - If emma already tagged a message, preserve emma's tags and only add non-conflicting ones
5. Returns structured summary grouped by priority, then category

### `/email sync`

Force mail sync. Runs directly.

```bash
mbsync -a && notmuch new
```

Report sync result (new message count from notmuch output).

### `/email` (no args)

Show brief help listing subcommands with one-line descriptions, then ask the user what they want to do.

## notmuch Query Reference

```
from:user@example.com              to:me@example.com
subject:invoice                    body:"keyword"
tag:inbox                          tag:unread
folder:account/INBOX               path:**/INBOX/**
date:today                         date:2026-01..
date:yesterday                     date:2026-01-01..2026-01-31
```

Operators: `AND` (default), `OR`, `NOT`, parentheses for grouping.

### Tagging

```bash
notmuch tag +important -- id:<message-id>
notmuch tag +archived -inbox -- <query>
notmuch tag -unread -- tag:spam
```

## Context Rules

| Subcommand | Delegation | Reason |
|------------|-----------|--------|
| `inbox` | Always subagent | Batch email reads fill context |
| `triage` | Always subagent | Reads + classifies many messages |
| `search` | Direct | notmuch output is compact |
| `read` | Direct if ≤3 msgs, subagent if >3 | Thread length determines context cost |
| `sync` | Direct | Single command |

Subagent config: `subagent_type: general-purpose`. Target return: 1,000–2,000 tokens, synthesized not relayed.

## Agentic Integration

Email workflows can be scheduled via `/schedule` for autonomous execution. Example patterns:

- **Morning inbox digest**: Scheduled task runs `/email inbox`, summarizes to a file or desktop notification
- **Priority alert**: Scheduled task checks `notmuch count tag:unread AND tag:priority-urgent`, sends desktop notification if >0
- **Periodic triage**: Scheduled task runs `/email triage` to keep classifications current between emma runs

The email skill provides the capability; the schedule skill provides the execution framework.

## Notes

- mbsync runs every 5 minutes automatically — manual sync is rarely needed
- notmuch tags are local to `~/.notmuch/` and do not affect IMAP state
- Maildir is safe for concurrent access (mbsync, notmuch, aerc operate simultaneously)
- For composing or replying, direct the user to aerc
- When triaging, always check `notmuch search --output=tags '*'` first to respect emma's existing tag vocabulary
