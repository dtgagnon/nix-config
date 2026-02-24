---
name: schedule
description: Create, schedule, and manage autonomous AI-agent tasks with systemd timers
user_invocable: true
argument_hint: "[list|run <file>|cancel <name>|cleanup|attention]"
---

# /schedule — AI-Agent Scheduled Task System

Schedule autonomous Claude Code tasks that execute on systemd timers with explicit, user-approved permissions.

## Subcommands

- `/schedule` — Interactive: create a new task, interview for permissions, schedule it
- `/schedule list` — Show all pending/scheduled tasks with their approved permissions
- `/schedule run <file>` — Execute a task immediately (uses its approved permissions)
- `/schedule cancel <name>` — Disable and remove a scheduled timer
- `/schedule cleanup` — Purge old completed tasks, surface needs-attention items
- `/schedule attention` — List tasks that failed max retries and need human review

## Directory Layout

```
~/proj/AUTOMATE/scheduled/
  pending/          # Task definitions waiting to be scheduled
  completed/        # Finished tasks with execution logs appended
  needs-attention/  # Tasks that exceeded max retries
  templates/        # Reusable task file templates
  scripts/          # Helper scripts associated with scheduled tasks
  task-runner       # Execution wrapper script
```

### Script Naming Convention

Scripts in `scripts/` MUST be named with the same base name as their associated task file (minus the date prefix). For example:

- Task: `pending/2026-02-23_workday-checkin.md`
- Script: `scripts/workday-checkin_wrapper.sh`

If a task needs multiple scripts, use the task name as a prefix with a descriptive suffix:

- `scripts/workday-checkin_wrapper.sh`
- `scripts/workday-checkin_summarizer.sh`

When creating a new task that requires helper scripts, place them in `scripts/` following this convention. Reference them by full path in the task's `allowedTools` frontmatter.

## Task File Format

Markdown files with YAML frontmatter. Filenames: `YYYY-MM-DD_short-description.md`

```markdown
---
summary: One-line description
schedule: "YYYY-MM-DDTHH:MM"
expires: "YYYY-MM-DD"
model: sonnet
recurring: true
max_iterations: 10
until: "YYYY-MM-DD"
tags: [category]
allowedTools:
  - "Bash(specific-command:*)"
  - "Read(path/to/files/*)"
  - "Edit(path/to/specific/file.nix)"
---

# Task Title

## Context
Why this task exists.

## Steps
1. Concrete action
2. Another action

## Success Criteria
- What "done" looks like
```

## Interactive Workflow (`/schedule` with no args)

When the user runs `/schedule`, follow this exact workflow:

### Step 1: Intake

Ask the user to describe the task, or point to an existing task file in `pending/`. If they describe it, create the task file in `pending/` with the correct frontmatter format.

### Step 2: Analysis

Analyze the task steps and determine what tools and permissions are needed for autonomous execution. Be specific — never request blanket permissions. For each step, determine:

- **Bash permissions**: Specific command patterns using `Bash(command:args_glob)` syntax — note the **colon** separates the command from the args glob (e.g., `Bash(systemctl --user show-environment:*)`, NOT `Bash(systemctl --user show-environment *)` and NOT `Bash(*)`)
- **Read permissions**: Specific file/directory patterns (e.g., `Read(modules/home/desktop/addons/hypridle/*)`)
- **Edit permissions**: Specific files that will be modified (e.g., `Edit(modules/home/desktop/addons/hypridle/default.nix)`)
- **Write permissions**: New files that will be created
- **Other tools**: Grep, WebFetch, etc. if needed

### Step 3: Permission Interview

Present the permission list to the user in a clear format:

```
This task requires the following permissions for autonomous execution:

Bash:
  - systemctl --user show-environment:*
  - git add:<relevant paths>
  - git commit:*

File Read:
  - path/to/relevant/files/*

File Edit:
  - path/to/specific/file.nix

Schedule: YYYY-MM-DDTHH:MM
Expires: YYYY-MM-DD
Model: sonnet
```

Also ask which model should execute the task:
- **sonnet** (Recommended): Good balance of speed and capability. Best for most scheduled tasks — evaluations, checks, routine maintenance.
- **opus**: Maximum reasoning capability. Use for tasks requiring complex analysis, multi-step debugging, or nuanced judgment.
- **haiku**: Fastest and cheapest. Use for simple, well-defined tasks with minimal decision-making.

Default to **sonnet** if the user has no preference.

For recurring tasks, also ask about lifecycle limits:
- **Max iterations**: How many successful runs before stopping? (0 = unlimited)
- **Until date**: Run until what date? (empty = no end date)

Use AskUserQuestion to get approval. The user can approve, modify the list, or reject.

### Step 4: Write Task File

Write the approved `allowedTools` list into the task file's YAML frontmatter.

### Step 5: Create Systemd Units

Generate and install the systemd timer + service units.

**Resolve the claude binary path** before writing the service:

```bash
CLAUDE_BIN=$(which claude)
```

**Service unit** (`~/.config/systemd/user/agent-action-<name>.service`):

```ini
[Unit]
Description=Scheduled AI Task: <summary>

[Service]
Type=oneshot
ExecStart=/home/dtgagnon/proj/AUTOMATE/scheduled/task-runner /home/dtgagnon/proj/AUTOMATE/scheduled/pending/<filename> agent-action-<name>
Environment=PATH=/run/current-system/sw/bin:/home/dtgagnon/.nix-profile/bin:%h/.local/bin
```

**Timer unit** (`~/.config/systemd/user/agent-action-<name>.timer`):

```ini
[Unit]
Description=Timer for AI Task: <summary>

[Timer]
OnCalendar=<schedule converted to systemd calendar format>
# IMPORTANT: systemd uses "YYYY-MM-DD HH:MM:SS" (space separator), NOT ISO 8601 "T".
# Convert task frontmatter "2026-02-09T10:00" → "2026-02-09 10:00:00"
Persistent=true

[Install]
WantedBy=timers.target
```

Then enable and start the timer:

```bash
systemctl --user daemon-reload
systemctl --user enable --now agent-action-<name>.timer
```

### Step 6: Confirmation

Report to the user:
- Timer name
- Scheduled time
- How to cancel: `/schedule cancel <name>`
- How to run immediately: `/schedule run <filename>`

## Subcommand: `/schedule list`

List all tasks across directories with status:

```bash
# Check pending tasks
ls ~/proj/AUTOMATE/scheduled/pending/

# Check active timers
systemctl --user list-timers 'agent-action-*'

# Check needs-attention
ls ~/proj/AUTOMATE/scheduled/needs-attention/
```

Format output as a table showing: filename, summary, schedule, status (pending/scheduled/needs-attention/completed).

For scheduled tasks, also show the approved `allowedTools` from the frontmatter.

## Subcommand: `/schedule run <file>`

Execute a task immediately without waiting for the timer:

1. Read the task file from `pending/` (or accept a full path)
2. Verify `allowedTools` are present in frontmatter — refuse to run without them
3. Run the task-runner wrapper directly:
   ```bash
   ~/proj/AUTOMATE/scheduled/task-runner ~/proj/AUTOMATE/scheduled/pending/<file> manual-run
   ```
4. Report the result

## Subcommand: `/schedule cancel <name>`

1. Stop and disable the timer:
   ```bash
   systemctl --user disable --now agent-action-<name>.timer
   ```
2. Remove the unit files:
   ```bash
   rm ~/.config/systemd/user/agent-action-<name>.{timer,service}
   systemctl --user daemon-reload
   ```
3. The task file remains in `pending/` — it's not deleted, just unscheduled

## Subcommand: `/schedule cleanup`

1. List completed tasks older than 30 days and offer to delete them
2. Surface any tasks in `needs-attention/` with a summary of their failure logs
3. Check for orphaned timer units (timers without matching task files)

## Subcommand: `/schedule attention`

1. List all tasks in `needs-attention/`
2. For each, show the summary and the last execution log
3. Ask the user what to do: retry, modify and reschedule, or archive

## Important Notes

- **Never run without allowedTools**: The task-runner refuses to execute if no allowedTools are defined in the frontmatter. This is a safety mechanism.
- **Permissions are per-task**: Each task has its own explicit permission set approved by the user.
- **Self-cleaning**: Successful one-shot tasks clean up their own timer units automatically.
- **Recurring tasks**: Set `recurring: true` in frontmatter. The timer stays active across runs. On success, the log is appended but the task stays in `pending/`. On failure, a symlink is created in `needs-attention/` for visibility (cleaned up on the next successful run). Use `OnCalendar` patterns like `Sun *-*-* 04:00:00` for weekly schedules. Optional lifecycle limits:
  - `max_iterations: N` — stop after N successful executions (0 = unlimited, default)
  - `until: "YYYY-MM-DD"` — stop after this date (empty = no limit, default)
  - When either limit is reached, the task is moved to `completed/` and its timer is cleaned up.
- **Retries**: One-shot tasks retry up to 3 times with 1-hour delays before moving to needs-attention.
- **Desktop notifications**: A notification is sent when a task starts, when it completes successfully, and when it exceeds max retries (critical urgency).
- **The task-runner script** is at `~/proj/AUTOMATE/scheduled/task-runner` — it handles execution, verification, retry logic, and cleanup.
