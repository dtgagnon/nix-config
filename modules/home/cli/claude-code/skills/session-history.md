---
name: session-history
description: Browse, search, and read conversation logs from previous Claude Code sessions
user_invocable: true
argument_hint: "[projects|list [project]|read <id>|search <query>|summary <id>]"
---

# /session-history — Claude Code Session Log Reader

Browse and search conversation history from previous Claude Code sessions across all projects.

## Data Locations

- **Session logs**: `~/.claude/projects/<project-dir>/<session-uuid>.jsonl`
- **Subagent logs**: `~/.claude/projects/<project-dir>/<session-uuid>/subagents/agent-*.jsonl`
- **Global input history**: `~/.claude/history.jsonl`

Project directory names are derived from the absolute working directory path with `/` replaced by `-` (e.g., `/home/dtgagnon/nix-config/nixos` becomes `-home-dtgagnon-nix-config-nixos`).

## JSONL Entry Format

Each `.jsonl` file contains one JSON object per line. Entry types:

| Type | Description | Key Fields |
|------|-------------|------------|
| `user` | User messages | `message.role`, `message.content` (string or content blocks), `timestamp`, `uuid` |
| `A` | Assistant responses | `message.role`, `message.content` (array of text/tool_use blocks), `timestamp`, `uuid` |
| `progress` | Tool execution progress | `data`, `toolUseID`, `timestamp` |
| `summary` | Conversation summaries | `summary` (short title string), `leafUuid` |
| `system` | System events | `slug`, `subtype`, `durationMs` |
| `file-history-snapshot` | File change tracking | `snapshot.trackedFileBackups`, `snapshot.timestamp` |

### Extracting Readable Content

- **User messages**: `entry.message.content` is usually a plain string
- **Assistant messages**: `entry.message.content` is an array; extract items where `item.type == "text"` and read `item.text`. Items where `item.type == "tool_use"` show tool calls with `item.name` and `item.input`
- **Summaries**: `entry.summary` is a short descriptive title for the conversation segment

## Subcommands

### `/session-history projects`

List all projects that have session history, with session counts and date ranges.

```bash
for d in ~/.claude/projects/*/; do
  project=$(basename "$d")
  count=$(ls "$d"*.jsonl 2>/dev/null | wc -l)
  if [ "$count" -gt 0 ]; then
    oldest=$(ls -tr "$d"*.jsonl 2>/dev/null | head -1 | xargs stat --format='%y' 2>/dev/null | cut -d' ' -f1)
    newest=$(ls -t "$d"*.jsonl 2>/dev/null | head -1 | xargs stat --format='%y' 2>/dev/null | cut -d' ' -f1)
    # Convert project dir name back to readable path
    readable=$(echo "$project" | sed 's/^-/\//' | sed 's/-/\//g')
    echo "$count sessions | $oldest to $newest | $readable"
  fi
done | sort -rn
```

Present as a table with columns: Sessions, Date Range, Project Path.

### `/session-history list [project]`

List recent sessions for a project (default: current project directory).

**Determine the project directory:**
- If no project argument given, derive from `$PWD`: replace `/` with `-` in the current path
- If a project name/path is given, match it against existing project directories (partial match is fine)

**List sessions with metadata:**

Use python to parse each JSONL file and extract:
1. Session UUID (filename without `.jsonl`)
2. File modification date (as proxy for session date)
3. First `summary` entry (if any) as the session title
4. First `user` message content (truncated to ~80 chars) as fallback title
5. Message count (number of `user` + `A` entries)
6. File size

```python
import json, os, glob, datetime

project_dir = os.path.expanduser("~/.claude/projects/<PROJECT>/")
sessions = []

for f in sorted(glob.glob(project_dir + "*.jsonl"), key=os.path.getmtime, reverse=True):
    sid = os.path.basename(f).replace(".jsonl", "")
    size = os.path.getsize(f)
    mtime = datetime.datetime.fromtimestamp(os.path.getmtime(f)).strftime("%Y-%m-%d %H:%M")
    summary = None
    first_msg = None
    msg_count = 0

    with open(f) as fh:
        for line in fh:
            try:
                d = json.loads(line)
                t = d.get("type")
                if t == "summary" and not summary:
                    summary = d.get("summary", "")
                if t == "user" and not first_msg:
                    content = d.get("message", {}).get("content", "")
                    if isinstance(content, list):
                        for c in content:
                            if c.get("type") == "text":
                                first_msg = c["text"][:80]
                                break
                    elif isinstance(content, str):
                        first_msg = content[:80]
                if t in ("user", "A"):
                    msg_count += 1
            except:
                pass

    title = summary or first_msg or "(no title)"
    sessions.append((sid, mtime, msg_count, size, title))

for sid, mtime, count, size, title in sessions[:20]:
    size_h = f"{size/1024:.0f}K" if size < 1048576 else f"{size/1048576:.1f}M"
    print(f"{sid[:8]}  {mtime}  {count:>4} msgs  {size_h:>6}  {title}")
```

Present as a table. Show the short UUID (first 8 chars) but note the user can use either short or full UUID for other commands.

### `/session-history read <id>`

Read the conversation from a specific session. The `<id>` can be a full UUID or a prefix (first 8+ chars).

**Resolve the session file:**
1. Find the matching `.jsonl` file by UUID prefix in the current project directory
2. If not found in the current project, search all project directories

**Extract and display the conversation:**

Parse the JSONL and display messages in chronological order:
- **User messages**: Show with a `## User` header and the message content
- **Assistant messages**: Show with a `## Assistant` header, including text content. For tool_use blocks, show tool name and a brief summary of inputs (not full input dumps unless specifically asked)
- **Summaries**: Show as `> Summary: <text>` blockquotes between conversation segments
- Skip `progress`, `file-history-snapshot`, and `system` entries unless the user asks for them

**Important**: Session logs can be very large. By default:
- Show the first 20 message pairs (user + assistant turns)
- If there are more, tell the user and offer to show more with an offset
- Offer to filter by keyword if the session is long

### `/session-history search <query>`

Search across session logs for a keyword or phrase.

**Scope**: Search the current project by default. Add `--all` to search all projects.

**Strategy**:
1. Use `grep -l` to find JSONL files containing the query string
2. For each matching file, parse and extract the matching messages with surrounding context
3. Show: session UUID (short), date, summary/title, and the matching message snippets

```bash
# Find sessions containing the query in the current project
grep -rl "<QUERY>" ~/.claude/projects/<PROJECT>/*.jsonl 2>/dev/null
```

Then for each matching file, use python to extract the specific messages containing the query and display them with context.

Present results grouped by session, with the session title and date, followed by matching message excerpts (truncated to ~200 chars with the match highlighted).

Limit to 10 sessions and 3 matches per session by default. Offer to expand if more exist.

### `/session-history summary <id>`

Show a quick overview of a session without full message content:
1. All `summary` entries (conversation topic titles)
2. Total message count (user vs assistant)
3. Tools used (unique tool names from `tool_use` blocks)
4. Files modified (from `file-history-snapshot` entries)
5. Session duration (first timestamp to last timestamp)
6. Whether subagent logs exist

### `/session-history` (no args)

Interactive mode. Show a brief help message listing the subcommands, then ask the user what they want to do.

## Important Notes

- **Session IDs**: UUIDs like `b3a35068-e0bc-442e-841f-cdfcc414cbcd`. Users can use the first 8 characters as shorthand.
- **Large files**: Some session logs are multi-megabyte. Always paginate output and avoid dumping entire files.
- **Privacy**: Session logs may contain sensitive data. Never expose full tool inputs/outputs by default — summarize tool calls unless the user asks for details.
- **Subagent logs**: Sessions that used the Task tool have a `<session-uuid>/subagents/` directory with separate JSONL files for each spawned agent. These follow the same format. Mention their existence but only read them if asked.
- **Performance**: For search operations across many sessions, use `grep` first to narrow down files before parsing JSONL with python. Avoid reading every file sequentially.
- **Current session**: The current active session's log file is being written to in real-time. It will appear in the list but may have incomplete data.
