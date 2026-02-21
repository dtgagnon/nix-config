---
name: codex
description: Code generation, exploration, and image analysis via Codex CLI
allowed-tools: Bash(codex exec:*), Bash(jq:*)
argument-hint: "[query]|build [description]|analyze [image-path] [question]"
---

# /codex — Codex CLI Workflows

Delegate tasks to Codex for code exploration, generation, and image analysis.

## Subcommands

### `/codex [query]`

Read-only code exploration. Default mode when no subcommand is given.

Run in read-only sandbox mode for safe code exploration:

!`codex exec "$ARGUMENTS" -s read-only --json 2>/dev/null | jq -r 'select(.type == "item.completed" and .item.type == "agent_message") | .item.text'`

**Use for:**
- Testing unfamiliar syntax before using it
- Generating example code for learning
- Validating regex patterns or command flags
- Quick code explanations

Review the response and integrate useful insights.

### `/codex build [description]`

Workspace-write mode — Codex can create and modify files.

Run: !`codex exec "$ARGUMENTS" --full-auto --json 2>/dev/null | jq -r 'select(.type == "item.completed" and .item.type == "agent_message") | .item.text'`

**Use for:**
- Generating boilerplate files
- Creating test fixtures
- Building quick utilities or scripts

Review what Codex created and verify it meets requirements.

### `/codex analyze [image-path] [question]`

Analyze images and diagrams in read-only mode.

Extract image path and question from: $ARGUMENTS

Run: !`codex exec "[question about image]" -i [image-path] -s read-only --json 2>/dev/null | jq -r 'select(.type == "item.completed" and .item.type == "agent_message") | .item.text'`

**Use for:**
- Architecture diagrams
- Screenshots of errors or UI
- Flowcharts or wireframes

Present Codex's analysis to inform our implementation.
