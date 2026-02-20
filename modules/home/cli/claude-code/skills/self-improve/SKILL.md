---
name: self-improve
description: Run the self-improvement pipeline to analyze usage, plan, and apply Claude Code configuration improvements
user_invocable: true
argument_hint: "[run|status|history|show <run-id>]"
---

# /self-improve — Claude Code Self-Improvement Pipeline

Analyze Claude Code usage insights, plan configuration improvements, get human approval, and execute approved changes.

**Prerequisite:** The `/insights` command must have been run recently (within 14 days). This pipeline consumes the existing `/insights` report and facets — it does not regenerate them.

## Subcommands

### `/self-improve` or `/self-improve run`

Trigger the self-improvement pipeline. This runs the four-stage process:

1. **Analysis** — Read the `/insights` report and facets, compare suggestions against current config, produce structured findings
2. **Planning** — Reason about findings and produce actionable change items with target files, descriptions, and risk levels
3. **Approval** — Desktop notification prompts the user to approve, review, or reject the plan
4. **Execution** — Apply approved changes to configuration files (scoped to only the planned target files)

To trigger:
```bash
systemctl --user start claude-self-improve.service
```

Or run the pipeline script directly:
```bash
~/proj/AUTOMATE/insights/self-improve-pipeline
```

The pipeline will notify the user if the `/insights` report is missing or stale (>14 days old).

### `/self-improve status`

Show the systemd timer status and last run outcome:

```bash
# Timer status
systemctl --user status claude-self-improve.timer
systemctl --user list-timers claude-self-improve*

# Last service run
systemctl --user status claude-self-improve.service
journalctl --user -u claude-self-improve.service --no-pager -n 30
```

### `/self-improve history`

List recent pipeline runs with their outcomes. Read from `~/proj/AUTOMATE/insights/runs/`:

```bash
# List all runs
ls -la ~/proj/AUTOMATE/insights/runs/

# For each run directory, summarize by reading:
# - pipeline.log (timestamps, stage progression)
# - analysis.json (finding count)
# - plan.json (item count)
# - approval.json (decision)
# - execution.json (success/failure counts)
```

Present results as a table with columns: Run ID, Findings, Plan Items, Approval, Executed, Cost.

### `/self-improve show <run-id>`

Display full details of a specific run. The `<run-id>` is the timestamp directory name (e.g., `2026-02-19_090000`).

Read and present:
1. `~/proj/AUTOMATE/insights/runs/<run-id>/pipeline.log` — Timeline of events
2. `~/proj/AUTOMATE/insights/runs/<run-id>/analysis.json` — All findings with categories and severities
3. `~/proj/AUTOMATE/insights/runs/<run-id>/plan.json` — Planned changes and skipped findings
4. `~/proj/AUTOMATE/insights/runs/<run-id>/approval.json` — Approval decision and method
5. `~/proj/AUTOMATE/insights/runs/<run-id>/execution.json` — Per-item execution results (if approved)
6. `~/proj/AUTOMATE/insights/runs/<run-id>/plan-summary.md` — Human-readable plan summary

## Pipeline Architecture

```
Stage 1: Analyze     Stage 2: Plan        Stage 3: Approve     Stage 4: Execute
claude -p (read)  ->  claude -p (no tools) -> notify-send (human) -> claude -p (write)
     |                    |                      |                     |
 analysis.json        plan.json            approval.json         execution.json
```

All artifacts stored in: `~/proj/AUTOMATE/insights/runs/<timestamp>/`

## Safety Features

- **Budget caps** per stage (default ~$11 total per run)
- **Mandatory human approval** before any file modifications
- **Dynamically scoped execution** — Stage 4 can only touch files named in the approved plan
- **No git commits** — user reviews and commits manually
- **No nixos-rebuild** — Nix changes are written but not activated
- **Full audit trail** — every run preserved in its own timestamped directory
- **Deny rules** from permissions.nix remain in effect (secrets, .env files protected)

## Configuration

The pipeline is configured via the `spirenix.cli.claude-code.selfImprove` NixOS module options:

| Option | Default | Purpose |
|--------|---------|---------|
| `enable` | `false` | Enable the pipeline |
| `insightsDir` | `$HOME/proj/AUTOMATE/insights` | Base directory |
| `schedule` | `Sun *-*-* 09:00:00` | Systemd timer schedule |
| `analysisModel` | `opus` | Model for analysis stage |
| `planModel` | `opus` | Model for planning stage |
| `executionModel` | `opus` | Model for execution stage |
| `budgetAnalysis` | `3.00` | Max USD for analysis |
| `budgetPlan` | `3.00` | Max USD for planning |
| `budgetExecution` | `5.00` | Max USD for execution |
| `approvalTimeout` | `1800` | Seconds before auto-reject (30 min) |
