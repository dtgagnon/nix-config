---
name: session-history
description: Browse, search, and read conversation logs from previous Claude Code sessions
user_invocable: true
argument_hint: "[list [--all]|search <query> [--all]|read <id>]"
---

# /session-history — Claude Code Session Log Reader

Browse and search conversation history from previous Claude Code sessions.

## Data Locations

- **Session logs**: `~/.claude/projects/<project-dir>/<session-uuid>.jsonl`
- **Subagent logs**: `~/.claude/projects/<project-dir>/<session-uuid>/subagents/agent-*.jsonl`

Project directory names are derived from the absolute working directory path with `/` replaced by `-` (e.g., `/home/dtgagnon/nix-config/nixos` → `-home-dtgagnon-nix-config-nixos`).

## JSONL Format Reference

Each `.jsonl` file contains one JSON object per line. Relevant entry types:

| Type | Key Fields |
|------|------------|
| `user` | `message.content` (string or content blocks array), `timestamp`, `uuid` |
| `A` | `message.content` (array of text/tool_use blocks), `timestamp`, `uuid` |
| `summary` | `summary` (short topic title string), `leafUuid` |

- **User messages**: `entry.message.content` is usually a plain string
- **Assistant messages**: `entry.message.content` is an array; extract `item.text` from items where `item.type == "text"`. Summarize `tool_use` items as `[Tool: <name>]` — don't extract inputs/outputs unless explicitly asked.
- **Summaries**: `entry.summary` is a short topic description generated when context is compressed

Ignore `progress`, `system`, and `file-history-snapshot` entries unless specifically relevant.

## Context Rules

Session logs are frequently multi-megabyte. These rules are mandatory.

1. **Never read session files in the main context.** The `read` and `search` subcommands must delegate to subagents via the Task tool (`subagent_type: general-purpose`). The subagent absorbs raw data and returns only a synthesis.

2. **Synthesize, don't relay.** Subagents return distilled findings — decisions, outcomes, what was tried and whether it worked, unresolved issues. Not reformatted raw data. Target **1,000–2,000 tokens** per subagent return.

3. **Search before parsing.** Use ripgrep (`rg`) to identify which files and lines contain relevant data before parsing any JSONL. Never iterate through entire files.

4. **The `list` subcommand is lightweight enough to run directly** in the main context (it extracts only titles and dates, not conversation content).

## Subcommands

### `/session-history list [--all]`

List recent sessions with topic titles and dates.

**Scope**: Current project by default. `--all` lists across all projects, grouped by project directory.

**For each JSONL file**, extract:
1. Session ID (filename stem — the UUID)
2. Date (file modification time)
3. Title: first `summary` entry, falling back to first `user` message content (truncated to ~80 chars)

Use `rg -m1 '"type":"summary"'` per file to grab the title line without reading the full file, then parse just that line for the `summary` field. Use `rg -m1 '"type":"user"'` for the fallback title.

Sort by date descending. Show 20 sessions by default. Display the short UUID (first 8 chars) — the user can use short or full UUIDs with other subcommands.

When using `--all`, group output by project directory and include the directory name as a section header.

### `/session-history search <query> [--all]`

Search session logs for a keyword or phrase. **Always delegate to a subagent** (`subagent_type: general-purpose`).

**Scope**: Current project by default. `--all` searches across all projects.

The subagent should:

1. **Find matching files** (fast, no parsing):
   ```bash
   rg -l "<QUERY>" ~/.claude/projects/<PROJECT>/*.jsonl
   ```

2. **Extract context from matches** (first 10 files max):
   Use `rg -n -C2 "<QUERY>"` to get matching lines with 2 lines of surrounding context, then parse those lines to extract message content.

3. **Return compact results** grouped by session:
   - Session ID (short), date, title (from summary or first user message)
   - Matching message excerpts (truncated to ~200 chars with match in context)
   - Limit to 3 matches per session by default

Return only formatted results — never raw JSONL.

### `/session-history read <id>`

Read and synthesize a specific session's conversation. The `<id>` can be a full UUID or prefix (8+ chars). **Always delegate to a subagent** (`subagent_type: general-purpose`).

The subagent should resolve the session file (current project first, then all projects) and return a synthesis using this format:

```markdown
<session id="b3a35068" date="2025-01-22">

## Topics
- OpenTurns Pagmo2 build failure
- Quickshell noctalia-shell customization

## Conversation
**[user]** How would we modify the noctalia-shell config?
**[assistant]** The config lives in overlays/noctalia-shell-bar-size/... [Tool: Read] [Tool: Grep]
**[user]** Can we change the bar height?
**[assistant]** Changed bar height from 32 to 40px. [Tool: Edit]

## Key Decisions & Outcomes
- Changed bar height from 32 to 40px in overlay
- Decided against modifying upstream package directly

## Files Changed
- overlays/noctalia-shell-bar-size/default.nix

</session>
```

Focus on: what was discussed, what was decided, what was tried and whether it worked, what files changed. Skip tool inputs/outputs and intermediate steps.

Show the first ~15 message exchanges by default. Report if more exist so the user can request continuation.

### `/session-history` (no args)

Show a brief help message listing the subcommands with one-line descriptions, then ask the user what they want to do.

## Notes

- **Session IDs**: UUIDs like `b3a35068-e0bc-442e-841f-cdfcc414cbcd`. First 8 characters work as shorthand.
- **Subagent logs**: Sessions that used the Task tool have a `<session-uuid>/subagents/` directory. Mention their existence in read output but only read them if asked.
- **Current session**: The active session's log is being written in real-time and may have incomplete data.
- **Privacy**: Summarize tool calls rather than exposing full inputs/outputs unless the user asks for details.
